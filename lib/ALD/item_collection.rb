require_relative 'collection'
require_relative 'local_filter'

module ALD
  class API
    # Public: Represents a (possibly filtered) set of items on an ALD server
    class ItemCollection < Collection
      # Internal: Create a new instance. This should not be called by library
      # consumers. Instead use API#items or #where to get a new instance.
      #
      # api        - the ALD::API instance this collection belongs to
      # conditions - a Hash of conditions items in this collection must meet
      # data       - an Array of Hashes representing the items in this
      #              collection:
      #              id      - the GUID of the item
      #              name    - the item's name
      #              version - the item's semver version
      def initialize(api, conditions = {}, data = nil)
        @conditions = conditions
        super(api, data)
      end

      # Public: Access an individual item by ID, name and version or index in
      # the collection. This method may trigger a HTTP request.
      #
      # Examples
      #
      #   items['185d265f24654545aad3f88e8a383339'] # access the item with this ID
      #   items['MyApp', '0.1.2'] # access a specific version of an item
      #   items[4] # access the 5th item in the collection (zero-based index)
      #            # This makes most sense in an explicitly ordered collection
      #
      # Returns the corresponding ALD::API::Item instance, or nil if not found
      #
      # Signature
      #
      #   [](id)
      #   [](name, version)
      #   [](index)
      #
      # id      - a GUID String uniquely identifying the item
      # name    - a String containing the item's name
      # version - a String containing the item's semver version
      # index   - an Integer with the item's zero-based index within the
      #           collection.

      # Internal: filter conditions that allow specifying a range, like
      # 'version-min=0.2.1&version-max=3.4.5'
      RANGE_CONDITIONS = %w[version downloads rating]

      # Public: Filter and/or sort this collection and return a new collection
      # containing a subset of its items.
      #
      # conditions - a Hash of conditions to filter for
      #              :name      - filter for items with this name (String)
      #              :user      - only return items by this user (given the user
      #                           name or the ID) (String)
      #              :type      - only return items of this type (String)
      #              :downloads - If given only a number, return only items with
      #                           this number of downloads. More commonly, pass
      #                           a string like '>= 4' or '<= 5' (or an array of
      #                           such strings) to select items in a range of
      #                           download counts.
      #              :rating    - Select items with a given rating. Like
      #                           for :downloads, ranges can be specified.
      #              :version   - Only items with a given semver version number.
      #                           Here as well, ranges can be specified. Semver
      #                           rules are taken into account when sorting.
      #              :stable    - Set to true to only return items whose semver
      #                           version indicates they're stable.
      #              :reviewed  - Set to true to filter for items that are marked
      #                           as reviewed by the server.
      #              :tags      - A tag or an array of tags to filter for.
      #              :sort      - an Array of sorting criteria, in descending
      #                           order of precedence; or a hash where the keys
      #                           are the sorting criteria, and the values (:asc,
      #                           :desc) indicate sorting order.
      #              :range     - A zero-based Range of items to return. This
      #                           makes most sense in combination with sorting.
      #                           Note that the range is relative to the
      #                           collection the operation is performed upon.
      #
      # Returns a new ItemCollection instance (or self, if conditions is nil)
      #
      # Raises ArgumentError if the conditions are invalid or incompatible with
      # this collection's conditions.
      def where(conditions)
        return self if conditions.nil? || conditions.empty?

        new_conditions = @conditions.merge(conditions) do |key|
          if RANGE_CONDITIONS.include?(key.to_s)
            merge_ranges(@conditions, conditions, key) # handle merging for cases like 'downloads >= 5' and 'downloads <= 9' etc.
          elsif key == :range # not a "range condition" in the sense used above
            range_offset(conditions[:range])
          elsif key == :sort
            conditions[key] # enable re-sorting
          else
            raise ArgumentError # for other overwrites fail!
          end
        end

        data = nil
        if initialized? && LocalFilter.can_filter?(conditions)
          data = LocalFilter.filter(@data, conditions)
          data = LocalFilter.sort(data, conditions[:sort]) if conditions.key?(:sort)
          data = data.slice(conditions[:range]) if conditions.key?(:range)
        end

        if data.nil?
          ItemCollection::new(@api, new_conditions)
        else
          ItemCollection::new(@api, new_conditions, data)
        end
      end

      private

      # Internal: Make a HTTP request to the ALD server to get the list of item
      # hashes matching this collection's conditions.
      #
      # Returns nothing.
      def request
        data = {}
        %w[name user type].each { |cond| data[cond] = @conditions[cond.to_sym] if @conditions.key?(cond.to_sym) } # literal conditions

        %w[stable reviewed].each do |cond| # field switches
          if @conditions.key?(cond.to_sym)
            data[cond] = {true => 'true', false => 'false', nil => 'both'}[@conditions[key.to_sym]]
          end
        end

        %w[downloads rating version].each do |cond| # range conditions
          if @conditions.key?(cond.to_sym)
            fields = @conditions[cond.to_sym].is_a?(Array) ? @conditions[cond.to_sym] : [@conditions[cond.to_sym]]
            fields.each do |field|
              match = RANGE_REGEX.match(field)
              if match.nil? # just a specific field
                data[cond] = field
              else # min or max
                data["#{cond}-#{match[1] == '>=' ? 'min' : 'max'}"] = match[2]
              end
            end
          end
        end

        data['tags'] = @conditions['tags'].join(',') if @conditions.key?(:tags)
        data['sort'] = @conditions[:sort].map { |k, dir| "#{dir == :desc ? '-' : ''}#{k}" }.join(',') if @conditions.key(:sort)

        if @conditions.key?(:range)
          data['start'] = @conditions[:range].min
          data['count'] = @conditions[:range].max - @conditions[:range].min + 1
        end

        url = "/items/#{data.empty? ? '' : '?'}#{URI.encode_www_form(data)}"
        @data = @api.request(url).map do |hash|
          hash['id'] = @api.normalize_id(hash['id'])
          hash
        end
      end

      # Internal: Used by Collection#each and Collection#[] to create new items.
      #
      # hash - a Hash describing the item, with the keys 'id', 'name' and 'version'.
      def entry(hash) # used by the Collection class
        @api.item(hash)
      end

      # Internal: Implements item access for #[]. See Collection#entry_filter
      # for more information.
      #
      # ItemCollection allows access by ID (String) or name and version
      # (both String).
      def entry_filter(args)
        if args.length == 1 && args.first.is_a?(String)
          { id: @api.normalize_id(args.first) }
        elsif args.length == 2
          { name: args.first, version: args.last }
        else
          raise ArgumentError
        end
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
      # ranges specified in #where are relativce to this collection, they must
      # be transformed to absolute rangeds before being passed to ::new.
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