require 'ALD/definition'
require 'ALD/definition_generator'
require 'ALD/package'

module ALD
  class Package
    class Generator
      attr_writer :definition

      def definition
        if @definition.is_a? ALD::Definition
          @definition
        elsif @definition.is_a? ALD::Definition::Generator
          @definition.generate!
        end
      end

      def valid?
        true && definition.valid?
      end

      def generate!(path)
        Package.create(self, path)
      end

      def self.from_package(package)
        nil
      end
    end
  end
end