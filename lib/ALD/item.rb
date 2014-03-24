require_relative 'collection_entry'
require 'date'

module ALD
  class API
    # Public: An item (e.g. a library or app) uploaded to an ALD server.
    class Item < CollectionEntry

      # Public: Get the ID of the item.
      #
      # Examples
      #
      #   puts item.id
      #
      # Returns a String of 32 characters, containing the item's GUID.
      #
      # Signature
      #
      #   item()

      # Public: Get the name of the item.
      #
      # Examples
      #
      #   puts "Item: #{item.name}"
      #
      # Returns a String containing the item name.
      #
      # Signature
      #
      #   name()

      # Public: Get the item version.
      #
      # Examples
      #
      #   puts "#{item.name} v#{item.version}"
      #
      # Returns a String containing the version of the item.
      #
      # Signature
      #
      #   version()

      # Public: Get the item's summary text. This method might trigger a HTTP
      # request.
      #
      # Returns a String summarizing the item's purpose and contents.
      #
      # Signature
      #
      #   summary()

      # Public: Get the item's description text. This method might trigger a
      # HTTP request.
      #
      # Returns a String with the item's description.
      #
      # Signature
      #
      #   description()

      # Public: Get the time the item was uploaded. This method might trigger a
      # HTTP request.
      #
      # Returns a DateTime describing the time the item was first uploaded to
      # the ALD server.
      #
      # Signature
      #
      #   uploaded()

      # Public: Get if the item has been marked as reviewed by the ALD server.
      # This method might trigger a HTTP request.
      #
      # Returns a Boolean indicating if the item was revieed or not.
      #
      # Signature
      #
      #   reviewed()

      # Public: Get the number of downloads for the item. This method might
      # trigger a HTTP request.
      #
      # Returns an Integer indicating how often the item was downloaded.
      #
      # Signature
      #
      #  downloads()

      # Public: Get the tags the item was tagged with. This method might
      # trigger a HTTP request.
      #
      # Returns an Array of Symbols representing the tags.
      #
      # Signature
      #
      #   tags()

      # Public: get author information from the item. This method might trigger
      # a HTTP request.
      #
      # Returns an Array of Hashes describing the authors.
      #
      # Signature
      #
      #   authors()

      # Public: Get the user who owns the item. This method might trigger a
      # HTTP request.
      #
      # Returns the ALD::API::User who owns the item.
      #
      # Signature
      #
      #   user()

      # Public: Get the ratings the item was given. This method might trigger a
      # HTTP request.
      #
      # Returns an Array of Integers representing the ratings given to the item
      # by users.
      #
      # Signature
      #
      #   ratings()

      # Internal: Create a new instance for given data. This method should not
      # called by library consumers. Instead access entries via API#item or
      # ItemCollection#[].
      #
      # api         - the ALD::API instance this item belongs to
      # data        - a Hash containing data concerning the item:
      #               id      - the GUID of the item
      #               name    - the name of the item
      #               version - the semver version of the item
      #               The above fields are mandatory. However, the hash may
      #               contain a lot more data about the item.
      # initialized - a Boolean indicating if data only contains the mandatory
      #               fields or *all* data on the item.
      def initialize(api, data, initialized = false)
        raise ArgumentError unless Item.valid_data?(data)
        super(api, data, initialized)
      end

      private

      # Internal: If the item was initialized with only mandatory data, use the
      # API to request all missing information.
      #
      # Returns nothing.
      def request
        @data = @api.request("/items/#{id}")
        @data['uploaded'] = DateTime.parse(@data['uploaded'])
        @data['tags'].map!(&:to_sym)
        @data['user'] = @api.user(@data['user'])
      end

      # Internal: Ensure a Hash contains all information necessary to be passed
      # to #new.
      #
      # data - the Hash to check for mandatory fields
      #
      # Returns true if the Hash is valid, false otherwise.
      def self.valid_data?(data)
        data.is_a?(Hash) && initialized_attributes.all? { |k| data.key?(k) }
      end

      # Internal: Override of CollectionEntry#initialized_attributes to enable
      # automatic method definition, in this case #id, #name and #version.
      #
      # Returns an Array of attribute names (String)
      def self.initialized_attributes
        %w[id name version]
      end

      # Internal: Override of CollectionEntry#requested_attributes to enable
      # automatic method definition.
      #
      # Returns an Array of attribute names (String)
      def self.requested_attributes
        %w[summary description uploaded reviewed downloads tags authors user ratings]
      end
    end
  end
end