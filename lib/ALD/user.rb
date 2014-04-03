require_relative 'collection_entry'
require 'date'

module ALD
  class API
    # Public: A user registered on an ALD server.
    class User < CollectionEntry
      # Public: Get the user's ID.
      #
      # Returns a 32-character string containing the user's GUID.
      #
      # Signature
      #
      #   id()

      # Public: Get the user's name
      #
      # Returns a String containing the user's name.
      #
      # Signature
      #
      #   name()

      # Public: Get the user's registration date. This method might trigger a
      # HTTP request.
      #
      # Returns a DateTime containing the date and time of the user's
      # registration on the ALD server.
      #
      # Signature
      #
      #   joined()

      # Public: Get the user's privileges on the ALD server. This method might
      # trigger a HTTP request.
      #
      # Returns an Array of Symbols representing privileges the user has.
      #
      # Signature
      #
      #   privileges()

      # Internal: Create a new instance. This method is called by API#user and
      # should not be called by library consumers.
      #
      # api         - The ALD::API instance this user belongs to
      # data        - a Hash containing the user's data
      # initialized - a Boolean indicating whether the given data is complete
      #               or further API requests are necessary.
      def initialize(api, data, initialized = false)
        super(api, data, initialized)
      end

      # todo: mail

      # Public: Get the MD5 hash of the user's mail adress. This method might
      # trigger a HTTP request.
      #
      # Returns a String with the hashed mail adress.
      def mailMD5
        request unless initialized?
        @data['mail-md5']
      end

      private

      # Internal: If the data given to the constructor was not complete, use
      # the API to request further information from the server.
      #
      # Returns nothing.
      def request
        @data = @api.request("/users/#{id}")
        @data['privileges'].map!(&:to_sym)
        @data['joined'] = DateTime.parse(@data['joined'])
      end

      # Internal: Override of CollectionEntry#initialized_attributes to enable
      # automatic method definition, in this case #id and #name.
      #
      # Returns an Array of attribute names (String)
      def self.initialized_attributes
        %w[id name]
      end

      # Internal: Override of CollectionEntry#requested_attributes to enable
      # automatic method definition, in this case #joined and #privileges.
      #
      # Returns an Array of attribute names (String)
      def self.requested_attributes
        %w[joined privileges]
      end
    end
  end
end