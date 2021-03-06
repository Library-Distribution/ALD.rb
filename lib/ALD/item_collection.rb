require_relative 'collection'
require_relative 'conditioned'
require_relative 'local_filter'

module ALD
  class API
    # Public: Represents a (possibly filtered) set of items on an ALD server
    class ItemCollection < Collection
      include Conditioned

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
        super(api, conditions, data)
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

      # Internal: filter conditions that allow specifying an array.
      ARRAY_CONDITIONS = %w[tags]

      # Internal: filter conditions that can be handled locally.
      LOCAL_CONDITIONS = %w[name version]

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
      #                           order of precedence; or a Hash where the keys
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
      #
      # Signature
      #
      #   where(conditions)

      private

      # Internal: Make a HTTP request to the ALD server to get the list of item
      # hashes matching this collection's conditions.
      #
      # Returns nothing.
      def request
        data = [
          exact_queries(%w[name user type]),
          switch_queries(%w[stable reviewed]),
          array_queries(%w[tags]),
          range_condition_queries(%w[downloads rating version]),
          sort_query,
          range_query
        ].reduce({}, :merge)

        url = "/items/#{data.empty? ? '' : '?'}#{URI.encode_www_form(data)}"
        @data = @api.request(url).map do |hash|
          hash['id'] = @api.normalize_id(hash['id'])
          hash
        end
      end

      # Internal: Make a HTTP request to the ALD server to get a single item.
      # Used by Collection#[].
      #
      # filter - a filter Hash as returned by #entry_filter
      #
      # Returns a Hash with all information about the item.
      #
      # Raises ArgumentError if the filters cannot be handled.
      def request_entry(filter)
        url = if filter.key?(:id)
          "/items/#{filter[:id]}"
        elsif %w[name version].all? { |k| filter.key?(k.to_sym) }
          "/items/#{filter[:name]}/#{filter[:version]}"
        else
          raise ArgumentError
        end

        @api.request(url)
      end

      # Internal: Used by Collection#each and Collection#[] to create new items.
      #
      # hash        - a Hash describing the item, with the keys 'id', 'name'
      #               and 'version'.
      # initialized - a Boolean indicating if the given Hash already contains
      #               all information about the item or only name and id.
      def entry(hash, initialized = false)
        @api.item(hash, initialized)
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
    end
  end
end