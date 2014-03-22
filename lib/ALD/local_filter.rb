module ALD
  class API
    class ItemCollection
      # Internal: Used by ItemCollection#where to filter items locally if
      # possible. All methods are module methods.
      module LocalFilter
        # Internal: Test if the given filter, sort and range conditions can be
        # handled locally or need a request to the server.
        #
        # conditions - a Hash of conditions to test
        #
        # Returns a Boolean; true if local filtering is possible, false
        # otherwise
        def self.can_filter?(conditions)
          conditions.keys.all? do |key|
            case key
              when :name, :range #, :version, :stable # todo: enable with semver
                true # these are always available and can be filtered by
              when :sort
                criteria = conditions[:sort].is_a?(Hash) ? conditions[:sort].keys : conditions
                criteria.all? { |c| [:name].include?(c) } # these sort fields are available # todo: enable semver and add :version
              else
                false
            end
          end
        end

        # Internal: Filter the given data locally
        #
        # data       - an Array of Hashes representing the items to filter
        # conditions - a Hash of conditions to filter for
        #
        # Returns the filtered data array
        #
        # Raises ArgumentError if a filter is detected that cannot be handled
        # locally. This can be prevented by calling ::can_filter? first.
        def self.filter(data, conditions)
          data.select do |entry|
            conditions.all? do |key, value|
              case key
                when :name
                  entry[key.to_s] == value
                # todo: when :version
                when :sort, :range
                  true # do that somewhere else
                else
                  raise ArgumentError # should be prevented by can_filter?
              end
            end
          end
        end

        # Internal: Sort the given data locally
        #
        # data - the Array of Hashes representing items
        # sort - either: a Hash, associating sorting criteria (symbols) to
        #        sorting direction (:asc ord :desc); or an Array of Symbols
        #        representing sorting criteria (direction defaults to :asc)
        #
        # Returns the sorted data array
        def self.sort(data, sort)
          sort = to_sort_hash(sort)
          data.sort do |a, b|
            sort.map { |key, dir| # map criteria and direction to +1/0/-1 sorting information
              if a[key.to_s] > b[key.to_s]
                dir == :asc ? +1 : -1
              elsif a[key.to_s] < b[key.to_s]
                dir == :asc ? -1 : +1;
              else
                0
              end
            }.find(0) { |s| s != 0 } # use highest-priority (i.e. first) sorting info != 0
          end
        end

        # Internal: Create a sorting hash from an array
        #
        # sort - a Hash or Array, in the format described in ::sort
        #
        # Returns a Hash, in the format described in ::sort
        def self.to_sort_hash(sort)
          if sort.is_a?(Hash)
            sort
          else
            Hash[sort.map { |c| [c, :asc] }]
          end
        end
        private_class_method :to_sort_hash
      end
    end
  end
end