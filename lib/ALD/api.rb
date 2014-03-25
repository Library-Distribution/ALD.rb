require_relative 'item_collection'
require_relative 'user_collection'
require_relative 'item'
require_relative 'user'
require_relative 'exceptions'

require 'net/http'
require 'net/http/digest_auth'
require 'json'

module ALD
  # Public: Access the ALD API programatically.
  class API

    # Public: Create a new instance to access an ALD server.
    #
    # root_url - a String pointing to the root URL of the server's API.
    #
    # Example
    #
    #   api = ALD::API.new('http://api.my_ald_server.com/v1/')
    def initialize(root_url)
      @root_url = URI(root_url)
      @item_store, @user_store = {}, {}
    end

    # Public: Get current authentication information Hash (see #auth=)
    attr_reader :auth

    # Public: Set authentication information for future requests.
    #
    # auth - a Hash containing the authentication information:
    #        :name     - the user name to use
    #        :password - the plaintext password to use
    #
    # Returns the hash that was passed.
    #
    # Raises ArgumentError if the passed hash does not have the specified keys.
    def auth=(auth)
      raise ArgumentError unless valid_auth?(auth)
      @auth = auth
    end

    # Public: Get a collection of items from this server. This calls
    # ItemCollection#where on the collection of all items. This method might
    # trigger a HTTP request.
    #
    # conditions - a Hash of conditions the items should meet.
    #              Valid conditions are documented at ItemCollection#where.
    #
    # Example
    #
    #   api.items.each { |i| puts i.name }
    #   api.items(name: 'MyApp') # equivalent to api.items.where(name: 'MyApp')
    #
    # Returns an ALD::API::ItemCollection containing the items.
    #
    # Raises ArgumentError if the specified conditions are invalid.
    def items(conditions = nil)
      @all_items ||= ItemCollection.new(self)
      @all_items.where(conditions)
    end

    # Public: Get a collection of users on this server. This calls
    # UserCollection#where on the collection of all users. This method might
    # trigger a HTTP request.
    #
    # conditions - a Hash of conditions the users should meet.
    #              Valid conditions are documented at UserCollection#where.
    #
    # Returns an ALD::API::UserCollection containing the users.
    def users(conditions = nil)
      @all_users ||= UserCollection.new(self)
      @all_users.where(conditions)
    end

    # Public: Get the API version supported by the server. This method triggers a HTTP
    # request.
    #
    # Returns the semver version string of the API.
    def version
      @version ||= request('/version')['version']
    end

    # Public: Get an individual item. This method is roughly equivalent to calling
    # ItemCollection#[] on API#items. Calling this method might trigger a HTTP
    # request.
    #
    # Examples
    #
    #   api.item('185d265f24654545aad3f88e8a383339')
    #   api.item('MyApp', '0.9.5')
    #
    #   # unlike ItemCollection#[], this also supports passing a hash:
    #   api.item({'id' => '185d265f24654545aad3f88e8a383339',
    #            'name' => 'MyApp',
    #            'version' => '4.5.6'})
    #   # However, this last form is only meant to be used internally and should
    #   # never be called by library consumers.
    #
    # Returns the ALD::API::Item instance representing the item, or nil if not
    # found.
    #
    # Raises ArgumentError if the arguments are not of one of the supported forms.
    #
    # Signature
    #
    #   item(id)
    #   item(name, version)
    #
    # id      - the GUID String of the item to return
    # name    - a String containing the item's name
    # version - a String containing the item's semver version
    def item(*args)
      if args.length == 1
        if args.first.is_a? String # GUID
          @item_store[normalize_id(args.first)] || items[args.first]
        elsif args.first.is_a? Hash # used internally to avoid multiple Item instances
          args.first['id'] = normalize_id(args.first['id'])
          @item_store[args.first['id']] ||= Item.new(self, args.first)
        end
      elsif args.length == 2 # name and version
        items[*args]
      else
        raise ArgumentError
      end
    end

    # Public: Get an individual user. This method is roughly equivalent to calling
    # UserCollection#[] on API#users. Calling this method might trigger a HTTP
    # request.
    #
    # Examples
    #
    #   api.user('6a309ac8a4304f5cb1e6a2982f680ca5')
    #   api.user('Bob')
    #
    #   # As #item, this method also supports being passed a Hash, which should
    #   # only be used internally.
    #
    # Returns the ALD::API::User instance representing the user, or nil if not
    # found.
    #
    # Raises ArgumentError if the arguments are not of one of the supported forms.
    #
    # Signature
    #
    #   user(id)
    #   user(name)
    #
    # id   - a 32-character GUID string containing the user's ID
    # name - a String containing the user's name
    def user(*args)
      if args.length == 1
        if args.first.is_a? String
          @user_store[normalize_id(args.first)] || users[args.first]
        elsif args.first.is_a? Hash
          args.first['id'] = normalize_id(args.first['id'])
          @user_store[args.first['id']] ||= User.new(self, args.first)
        end
      else
        raise ArgumentError
      end
    end

    # Internal: Given a GUID string, bring it into a standardized form. This
    # is used internally to make comparing GUIDs easier.
    #
    # id - the GUID String to normalize
    #
    # Returns the normalized GUID String.
    def normalize_id(id)
      id.upcase.gsub(/[^0-9A-F]/, '')
    end

    # Internal: The default headers to be used in #request.
    DEFAULT_HEADERS = {
      'Accept' => 'application/json'
    }

    # Internal: Make a raw request to the ALD server. This is used internally,
    # and library consumers should only call it if they are familiar with the
    # ALD API.
    #
    # url     - the URL String, relative to the root URL, to request against.
    # method  - a Symbol indicating the HTTP method to use. Supported: :get, :post
    # headers - a Hash containing additional headers (for the defaults see
    #           ::DEFAULT_HEADERS).
    # body    - If method is :post, a request body to use.
    #
    # Returns The response body; as Hash / Array if the 'Content-type' header
    # indicates a JSON response; as raw String otherwise.
    #
    # Raises ArgumentError is method is not supported.
    #
    # Raises API::RequestError if the response code is not in (200...300).
    def request(url, method = :get, headers = {}, body = nil)
      Net::HTTP.start(@root_url.host, @root_url.port) do |http|
        url = @root_url + url

        request = create_request(method, url)
        DEFAULT_HEADERS.merge(headers).each do |k, v|
          request[k] = v
        end

        response = http.request(request)
        response = request_with_auth(http, request, url, response) if response.code.to_i == 401

        raise RequestError unless (200...300).include?(response.code.to_i)
        if response['Content-type'].include?('application/json')
          JSON.parse(response.body)
        else
          response.body
        end
      end
    end

    private

    # Internal: Create a new Net::HTTPRequest for the given method.
    #
    # method - a Symbol indicating the HTTP verb (lowercase
    # url    - the URI to request
    #
    # Returns a Net::HTTPRequest for the given method.
    #
    # Raises ArgumentError if the verb is not supported.
    def create_request(method, url)
      case method
        when :get
          Net::HTTP::Get.new url.request_uri
        when :post
          Net::HTTP::Post.new url.request_uri
        else
          raise ArgumentError
      end
    end

    # Internal: Retry a request with authentication
    #
    # http            - a Net::HTTP object to use for the request
    # request         - the Net::HTTPRequest to use
    # url             - the URI that is requested
    # failed_response - the response that was given when requesting without auth
    #
    # Returns a successful Net::HTTPResponse for the request.
    #
    # Raises NoAuthError if @auth is not set.
    #
    # Raises UnsupportedAuthMethodError if the server uses a not supported auth
    # method.
    #
    # Raises InvalidAuthError if the authenticated request yields a 401 response.
    def request_with_auth(http, request, url, failed_response)
      raise NoAuthError if @auth.nil?
      case auth_method(failed_response)
        when :basic
          request.basic_auth(@auth[:name], @auth[:password])
        when :digest
          url.user, url.password = @auth[:name], @auth[:password]
          request.add_field 'Authorization', Net::HTTP::DigestAuth.new.auth_header(url, failed_response['WWW-Authenticate'], request.method)
        else
          raise UnsupportedAuthMethodError
      end

      response = http.request(request)
      raise InvalidAuthError if response.code.to_i == 401
      response
    end

    # Internal: Get the authentication method used by a server
    #
    # response - the Net::HTTPResponse to examine
    #
    # Returns the used method as Symbol, e.g. :digest or :basic
    def auth_method(response)
      response['WWW-Authenticate'].strip.split(' ')[0].downcase.to_sym
    end

    # Internal: Check if a Hash contains valid auth data
    #
    # auth - the Hash to check
    #
    # Returns true, if the Hash contains the necessary keys, false otherwise.
    def valid_auth?(auth)
      auth.is_a?(Hash) && %w[name password].all? { |k| auth.key?(k.to_sym) }
    end
  end
end