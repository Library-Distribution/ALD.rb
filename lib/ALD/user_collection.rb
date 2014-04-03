require_relative 'collection'
require_relative 'conditioned'

module ALD
  class API
    # Public: Represents a collection of users on an ALD server.
    class UserCollection < Collection
      include Conditioned

      # Internal: Create a new collection instance. Library consumers should
      # not directly call this, but instead obtain new instances from API#users
      # or #where.
      #
      # api        - the ALD::API instance this collection belongs to
      # conditions - the Hash of conditions users in this collection must meet
      # data       - an Array of Hashes containing the data about the users in
      #              the collection. May be nil.
      def initialize(api, conditions = {}, data = nil)
        super(api, conditions, data)
      end

      # Public: Access an individual user in the collection.
      #
      # Examples
      #
      #   puts api.users['Fred'].name # => 'Fred'
      #
      # Returns the ALD::API::User instance representing the user, or nil if
      # not found.
      #
      # Signature
      #
      #   [](name)
      #   [](id)
      #
      # name - a String containing the user's name
      # id   - a 32-character String containing the user's GUID

      # Internal: filter conditions that allow specifying a range. See #where.
      RANGE_CONDITIONS = %w[joined]

      # Internal: filter conditions that allow specifying an array.
      ARRAY_CONDITIONS = %w[privileges]

      # Internal: filter conditions that can be handled locally.
      LOCAL_CONDITIONS = %w[name]

      # Public: Return a new collection containing a subset of the users in
      # this collection.
      #
      # conditions - a Hash of conditions the users in the new collection must
      #              meet:
      #              :range      - a zero-based Integer Range of users in this
      #                            collection that should be in the new
      #                            collection. Note that this is applied AFTER
      #                            the other conditions.
      #              :joined     - the date and time the user registered to the
      #                            server. Instead of specifying an exact value,
      #                            You can specify a comparison such as
      #                            '>= 2013-03-04 13:00:00'.
      #              :privileges - an Array of privileges the user should have.
      #              :sort       - an Array of sorting criteria, in descending
      #                            order of precedence; or a Hash where the keys
      #                            are the sorting criteria, and the values
      #                            (:asc, :desc) indicate sorting order.
      #
      # Returns a new UserCollection or self if conditions is nil.
      #
      # Raises ArgumentError if the new conditions are incompatible with the
      # current ones.
      #
      # Signature
      #
      #   where(conditions)

      private

      # Internal: Make a HTTP request to the ALD server to get the list of user
      # hashes matching this collection's conditions.
      #
      # Returns nothing.
      def request
        data = [
          range_condition_queries(%w[joined]),
          array_queries(%w[privileges]),
          sort_query,
          range_query
        ].reduce({}, :merge)

        url = "/users/#{data.empty? ? '' : '?'}#{URI.encode_www_form(data)}"
        @data = @api.request(url).map do |hash|
          hash['id'] = @api.normalize_id(hash['id'])
          hash
        end
      end

      # Internal: Make a HTTP request to the ALD server to get a single user.
      # Used by Collection#[].
      #
      # filter - a filter Hash as returned by #entry_filter
      #
      # Returns a Hash with all information about the user.
      #
      # Raises ArgumentError if the filters cannot be handled.
      def request_entry(filter)
        url = if %w[id name].any? { |k| filter.key?(k.to_sym) }
          "/users/#{filter[:id] || filter[:name]}"
        else
          raise ArgumentError
        end

        @api.request(url)
      end

      # Internal: Used by Collection#each and Collection#[] to create new users.
      #
      # hash        - a Hash describing the item, with the keys 'id' and 'name'
      # initialized - a Boolean indicating if the given Hash already contains
      #               all information about the user or only name and id.
      def entry(hash, initialized = false)
        @api.user(hash, initialized)
      end

      # Internal: Implements user access for #[]. See Collection#entry_filter
      # for more information.
      #
      # UserCollection allows access by ID (String) or name (String).
      def entry_filter(args)
        unless args.length == 1 && args.first.is_a?(String)
          raise ArgumentError
        end
        if /^[0-9a-fA-F]{32}$/ =~ args.first
          { id: @api.normalize_id(args.first) }
        else
          { name: args.first }
        end
      end
    end
  end
end