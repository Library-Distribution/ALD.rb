module ALD
  class API
    # Internal: Base class for entries in a collection returned by the ALD API.
    # This class is used internally and should not be called by library
    # consumers.
    #
    # Child classes inheriting from this class must support:
    #   * @data        - a Hash containing the entry's data
    #   * @initialized - a Boolean indicating whether @data is yet complete or
    #                    not
    #   * #request     - load missing information into @data
    class CollectionEntry
      # Internal: Create a new entry with the given data
      #
      # api         - the ALD:API instance this entry belongs to
      # data        - the initial, possibly uncomplete @data hash
      # initialized - a Boolean indicating whether data is already complete or
      #               not
      def initialize(api, data, initialized = false)
        @api, @data, @initialized = api, data, initialized

        self.class.initialized_attributes.each do |attr|
          self.class.send(:define_method, attr.to_sym) do
            @data[attr]
          end
        end

        self.class.requested_attributes.each do |attr|
          self.class.send(:define_method, attr.to_sym) do
            request unless initialized?
            @data[attr]
          end
        end
      end

      # Public: Indicate whether all data concerning this entry is available
      # or not. If false, a property retrieval from this entry *may* trigger a
      # HTTP request.
      #
      # Returns a Boolean, true if all data is present, false otherwise.
      def initialized?
        @initialized
      end

      # Internal: Child classes override this to specify attributes that are
      # always present in @data. For each such attribute, a retrieval method is
      # dynamically defined.
      #
      # Returns an Array of attribute names (String)
      def self.initialized_attributes
        []
      end

      # Internal: Child classes override this to specify attributes that are
      # *not* always present in @data. For each such attribute, a retrieval
      # method including a call to #request is dynamically defined.
      #
      # Returns an Array of attribute names (String)
      def self.requested_attributes
        []
      end
    end
  end
end