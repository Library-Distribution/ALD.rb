require_relative 'collection_entry'

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

      private

      # Internal: If the data given to the constructor was not complete, use
      # the API to request further information from the server.
      #
      # Returns nothing.
      def request
        # todo
      end

      # Internal: Override of CollectionEntry#initialized_attributes to enable
      # automatic method definition, in this case #id and #name.
      #
      # Returns an Array of attribute names (String)
      def self.initialized_attributes
        %w[id name]
      end
    end
  end
end