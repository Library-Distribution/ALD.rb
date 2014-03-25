module ALD
  class API
    # Internal: used by Collection classes to work with special conditions in #where.
    #
    # Requires @conditions to be the instance's condition Hash.
    module Conditioned
      private

      # Internal: The HTTP query conditions for the range specified in the
      # instance's conditions.
      #
      # Returns a Hash, that contains the query parameters matching the range
      # specified in the conditions, or an empty Hash if there is no range
      # specified.
      def range_query
        data = {}
        if @conditions.key?(:range)
          data['start'] = @conditions[:range].min
          data['count'] = @conditions[:range].max - @conditions[:range].min + 1
        end
        data
      end

      # Internal: The HTTP query conditions for the sorting specified in the
      # instance's conditions.
      #
      # Returns a Hash containing the query parameters matching the specified
      # sorting, or an empty Hash if there's no sorting specified.
      def sort_query
        Hash[
          present_conditions(%w[sort]).map { |cond| [cond, @conditions[cond.to_sym].map { |k, dir| "#{dir == :desc ? '-' : ''}#{k}" }.join(',')] }
        ]
      end

      # Internal: The HTTP query conditions for exact queries for a set of
      # given conditions.
      #
      # conds - an Array of Strings, containing the condition names to handle
      #
      # Returns a Hash with the query parameters matching the instance's values
      # on the specified conditions, or an empty Hash, if there are none.
      def exact_queries(conds)
        Hash[
          present_conditions(conds).map { |cond| [cond, @conditions[cond.to_sym]] }
        ]
      end

      # Internal: The HTTP query conditions for queries for an array of values
      # for the given conditions.
      #
      # conds - an Array of Strings, containing the condition names to handle
      #
      # Returns a Hash with the query parameters matching the instance's values
      # on the specified conditions, or an empty Hash.
      def array_queries(conds)
        Hash[
          present_conditions(conds).map { |cond| [cond, @conditions[cond.to_sym].join(',')] }
        ]
      end

      # Internal: The HTTP query conditions for queries with conditions that
      # can be switched on, off or indeterminate.
      #
      # conds - an Array of Strings, containing the condition names to handle
      #
      # Returns a Hash with the query parameters matching the instance's values
      # on the specified conditions, or an empty Hash.
      def switch_queries(conds)
        map = {true => 'true', false => 'false', nil => 'both'}
        Hash[
          present_conditions(conds).map { |cond| [cond, map[@conditions[cond.to_sym]]] }
        ]
      end

      # Internal: The HTTP query conditions for queries with conditions that
      # allow specifying a range of values.
      #
      # conds - an Array of Strings, containing the condition names to handle
      #
      # Returns a Hash with the query parameters matching the instance's values
      # on the specified conditions, or an empty Hash.
      def range_condition_queries(conds)
        Hash[
          present_conditions(conds).map { |cond|
            fields = @conditions[cond.to_sym].is_a?(Array) ? @conditions[cond.to_sym] : [@conditions[cond.to_sym]]
            fields.map do |field|
              match = RANGE_REGEX.match(field)
              if match.nil? # just a specific field
                [cond, field]
              else # min or max
                ["#{cond}-#{match[1] == '>=' ? 'min' : 'max'}", match[2]]
              end
            end
          }.flatten(1)
        ]
      end

      # Internal: Get the subset of conditions that are present on the instance
      #
      # conds - an Array of Strings, containing the condition names to check
      #
      # Returns an Array of Strings with a subset of the given conds, namely
      # those that are present on @conditions.
      def present_conditions(conds)
        conds.select { |cond| @conditions.key?(cond.to_sym) }
      end

      # Internal: A regex to determine if a range condition is specifying a range.
      RANGE_REGEX = /^\s*(<\=|>\=)\s*(.*)$/

      # Internal: Handle condition conflicts for range conditions. Used by #where.
      #
      # old_conds - the old condition Hash
      # new_conds - the new condition Hash to be applied on top of the old one
      # key       - the conflicting key
      #
      # Returns the value that should be used in the merged conditions.
      #
      # Raises ArgumentError if the conflict cannot be resolved.
      def merge_ranges(old_conds, new_conds, key)
        constraints = [new_conds[key], old_conds[key]]
        data = constraints.map do |c|
          match = RANGE_REGEX.match(c)
          c.nil? ? [nil, c] : [match[1], match[2]]
        end
        ops, values = data.map(&:first), data.map(&:last)

        if ops[0] != ops[1] # one min, one max OR one min/max, one exact
          constraints # => keep both

        elsif ops.none?(&:'nil?') # two range constraints of same type
          ops[0] == '>=' ? ">= #{values.max}" : "<= #{values.min}" # todo: handle semver

        else # two exact values
          if constraints[0].strip == constraints[1].strip # if both are the same, just keep one
            constraints[0]
          else # otherwise this can't be good - throw an error
            raise ArgumentError
          end
        end
      end

      # Internal: Compute an absolute Range from a given relative Range. As
      # ranges specified in #where are relative to this collection, they must
      # be transformed to absolute ranges before being passed to ::new.
      #
      # new_range - the relative Range to transform
      #
      # Returns the absolute Range.
      #
      # Raises ArgumentError if the relative Range does not fit into this
      # collection's Range.
      def range_offset(new_range)
        if @conditions[:range].nil?
          min, max = 0, Float::Infinity
        else
          min, max = @conditions[:range].min, @conditions[:range].max
        end

        new_min = min + new_range.min
        new_max = new_min + new_range.max - new_range.min # == new_min + new_range.size - 1
        raise ArgumentError if new_min > max || new_max > max

        (new_min..new_max)
      end
    end
  end
end