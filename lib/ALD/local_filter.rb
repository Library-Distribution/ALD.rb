require 'semantic'

module ALD
  class API
    class Collection
      # Internal: Used by ItemCollection/UserCollection#where to filter data
      # locally if possible. All methods are module methods.
      module LocalFilter
        # Internal: Apply certain conditions on given data. This is a wrapper
        # method that calls ::filter, ::sort (if necessary) and applies a :range
        # condition (if specified).
        #
        # data       - an Array of Hashes representing the entries to apply
        #              conditions upon
        # conditions - the Hash of conditions to apply
        #
        # Returns the modified data Array.
        #
        # Raises ArgumentError if the conditions cannot be applied. This can be
        # avoided by passing them to ::can_apply? beforehand.
        def self.apply_conditions(data, conditions)
          data = filter(data, conditions)
          data = sort(data, conditions[:sort])  if conditions.key?(:sort)
          data = data.slice(conditions[:range]) if conditions.key?(:range)
          data
        end

        # Internal: Test if the given filter, sort and range conditions can be
        # applied locally or need a request to the server.
        #
        # conditions - a Hash of conditions to test
        # local_keys - an Array of Strings or Symbols, containing the key names
        #              that are available locally
        #              Related: CollectionEntry::initialized_attributes
        #
        # Returns a Boolean; true if local application is possible, false
        # otherwise
        def self.can_apply?(conditions, local_keys)
          local_keys.map!(&:to_sym) # symbolize keys

          conditions.all? do |key, value|
            if key == :sort
              sort_criteria(value).all? { |c| local_keys.include?(c) }
            else
              local_keys.include?(key) || key == :range # range is always supported
            end
          end
        end

        # Internal: Filter the given data locally. This does not support range
        # or switch conditions. Array conditions also only work if the values
        # are exactly the same, i.e. the same entries in the same order.
        #
        # data       - an Array of Hashes representing the entries to filter
        # conditions - a Hash of conditions to filter for
        #
        # Returns the filtered data array
        #
        # Raises ArgumentError if a filter is detected that cannot be handled
        # locally. This can be prevented by calling ::can_filter? first.
        def self.filter(data, conditions)
          data.select do |entry|
            conditions.all? do |key, value|
              if [:sort, :range].include?(key)
                true # must be done somewhere else
              elsif entry.key?(key.to_s) # should be a locally available key
                entry[key.to_s] == value
              else
                raise ArgumentError  # should be prevented by can_filter?
              end
            end
          end
        end

        # Internal: Sort the given data locally
        #
        # data - the Array of Hashes representing entries
        # sort - either: a Hash, associating sorting criteria (symbols) to
        #        sorting direction (:asc ord :desc); or an Array of Symbols
        #        representing sorting criteria (direction defaults to :asc)
        #
        # Returns the sorted data array
        def self.sort(data, sort)
          sort = to_sort_hash(sort)
          data.sort do |a, b|
            sortings(sort, a, b).find { |s| s != 0 } || 0 # use highest-priority (i.e. first) sorting info != 0
          end
        end

        # Internal: Get the sort order for given criteria.
        #
        # sort - a Hash as described in ::sort
        # a, b - the Hashes to compare
        #
        # Returns an Array of Integers (-1, 0, +1), where each represents the
        # sort order for one of the sort keys.
        def self.sortings(sort, a, b)
          sort.map do |key, dir|
            key = key.to_s
            if key == 'version'
              result = Semantic::Version.new(a[key]) <=> Semantic::Version.new(b[key])
            else
              result = a[key] <=> b[key]
            end
            dir == :asc ? result : -result
          end
        end
        private_class_method :sortings

        # Internal: Create a sorting Hash from an Array.
        #
        # sort - a Hash or Array, in the format described in ::sort
        #
        # Returns a Hash, in the format described in ::sort.
        def self.to_sort_hash(sort)
          if sort.is_a?(Hash)
            sort
          else
            Hash[sort.map { |c| [c, :asc] }]
          end
        end
        private_class_method :to_sort_hash

        # Internal: The inverse of ::to_sort_hash.
        #
        # sort - an Array or Hash, in the format described in ::sort
        #
        # Returns an Array, in the format described in ::sort.
        def self.sort_criteria(sort)
          sort.is_a?(Hash) ? sort.keys : sort
        end
        private_class_method :sort_criteria
      end
    end
  end
end