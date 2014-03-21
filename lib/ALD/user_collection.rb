require_relative 'collection'

module ALD
  class API
    class UserCollection < Collection
      def initialize(api, conditions = {}, data = nil)
        super(api, data)
      end

      def where(conditions)
      end

      private

      def entry(hash)
      end

      def request
      end
    end
  end
end