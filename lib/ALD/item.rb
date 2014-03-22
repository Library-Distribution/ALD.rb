require_relative 'collection_entry'

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
        # todo
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
    end
  end
end