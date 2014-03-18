require 'ALD/definition'
require 'ALD/definition_generator'
require 'ALD/package'
require 'ALD/exceptions'

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
        true && @definition.valid?
      end

      # Creates a new package file from the given data
      #
      # generator - an ALD::Package::Generator instance to create the package from
      # path - the path where to create the package. This file must not yet exist.
      #
      # Returns a new ALD::Package instance representing the newly created file
      def generate!(path)
        if File.exists? path
          raise IOError, "Destination '#{path}' already exists!"
        end

        raise InvalidPackageError unless valid?

        archive = Zip::File.open(path, Zip::File::CREATE)

        archive.get_output_stream('definition.ald') do |s|
          s << definition.to_s
        end

        files.each do |path, src|
          archive.add(path, src)
        end

        Package.new(file)
      end

      def self.from_package(package)
        nil
      end
    end
  end
end