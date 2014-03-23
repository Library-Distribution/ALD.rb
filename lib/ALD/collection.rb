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
      # api        - the ALD::API instance this collection belongs to
      # conditions - a Hash of conditions entries in this collection must meet
      # data       - an Array of Hashes for @data. May be nil.
      def initialize(api, conditions = {}, data = nil)
        @api, @conditions, @data = api, conditions, data
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

      # Internal: Access an entry in the collection.
      #
      # Actual arguments and behaviour depends on child classes.
      #
      # Returns an entry of the collection, or nil if none is found.
      #
      # Raises ArgumentError if the given arguments are invalid.
      def [](*args)
        if args.length == 1 && args.first.is_a?(Integer)
          request unless initialized?
          entry(@data[args.first])
        else
          filter = entry_filter(args)

          # todo: if not initialized?, do not request; instead get full entry description (new method request_entry(filter)) and pass it to #entry with initialized = true
          request unless initialized?
          entry = @data.find { |hash| filter.keys.all? { |k| hash[k.to_s] == filter[k] } }

          entry.nil? ? nil : entry(entry)
        end
      end

      # Public: Indicate if all data in this collection is present. If false,
      # accessing an entry or iterating over entries in this collection may
      # trigger a HTTP request.
      #
      # Returns a Boolean; true if all data is present, false otherwise
      def initialized?
        !@data.nil?
      end

      private

      # Internal: Get filter conditions for an entry. Used by #[] to get an
      # entry based on the given arguments.
      #
      # This method is a mere placeholder. Child classes must override it to
      # implement their access semantics for entries.
      #
      # args - an Array of arguments to convert into conditions
      #
      # Returns the Hash of conditions, where each key represents a property
      # of the entry to be found that must equal the corresponding value.
      #
      # Raises ArgumentError if the arguments cannot be converted.
      def entry_filter(args)
        {}
      end
    end
  end
end