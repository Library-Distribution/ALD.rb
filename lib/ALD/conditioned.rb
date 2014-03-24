module ALD
  class API
    # Internal: used by Collection classes to work with special conditions in #where.
    #
    # Requires @conditions to be the instance's condition Hash.
    module Conditioned
      private

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