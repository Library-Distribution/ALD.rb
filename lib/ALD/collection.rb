module ALD
  class API
    # Internal: Base class for collections of entries returned by a request to
    # the ALD API.
    #
    # Child classes inheriting from this class must support:
    #
    #   @data        - Array of Hashes necessary to create a new entry of this
    #                  collection, initially nil
    #   #entry(hash) - create a new entry from the given Hash
    #   #request     - load the @data Array
    class Collection

      # This class includes the Enumerable module.
      include Enumerable

      # Internal: Create a new Collection
      #
      # api  - the ALD::API instance trhis collection belongs to
      # data - an Array of Hashes for @data. May be nil.
      def initialize(api, data)
        @api, @data = api, data
      end

      # Public: Iterate over the entries in this collection
      #
      # Yields an entry, as returned by #entry
      def each
        request unless initialized?
        @data.each do |hash|
          yield entry(hash)
        end
      end

      # Public: Access an entry by index in the collection
      #
      # index - the 0-based integer index of the item in the collection
      #
      # Returns the (index+1)th entry in the collection, as returned by #entry
      def [](index)
        request unless initialized?
        entry(@data[index])
      end

      # Public: Indicate if all data in this collection is present. If false,
      # accessing an entry or iterating over entries in this collection may
      # trigger a HTTP request.
      #
      # Returns a Boolean; true if all data is present, false otherwise
      def initialized?
        !@data.nil?
      end
    end
  end
end