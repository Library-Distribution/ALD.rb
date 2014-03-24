require_relative 'collection'

module ALD
  class API
    class UserCollection < Collection
      def initialize(api, conditions = {}, data = nil)
        super(api, conditions, data)
      end

      def where(conditions)
      end

      private

      def entry(hash)
        @api.user(hash)
      end

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

      def request
      end
    end
  end
end