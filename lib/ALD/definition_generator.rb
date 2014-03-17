module ALD
  class Definition
    class Generator
      def generate!
        Definition.create(self)
      end

      def valid?
      end
    end
  end
end