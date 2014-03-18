require 'zip'
require 'ALD/definition'
require 'ALD/exceptions'

module ALD
  # Represents an ALD package file containing an app or library and its definition
  class Package

    # The rubyzip Zip::File object containing the data
    attr_reader :archive

    # The ALD::Definition instance representing the definition contained in the package
    attr_reader :definition

    # Opens a new ALD package file
    #
    # file - a Zip::File instance or the path to the file
    #
    # Returns a new ALD::Package instance representing the package file
    def initialize(file)
      if file.is_a? Zip::File
        @archive = file
      else
        @archive = Zip::File.open(file)
      end

      def_entry = @archive.find_entry('definition.ald')
      raise NoDefinitionError if def_entry.nil?

      @definition = Definition.new(def_entry.get_input_stream)
      raise InvalidPackageError, 'The given ZIP file is not a valid ALD archive!' unless Package.valid?(@archive, @definition)

      # file access
    end

    # Closes a no longer required package
    def close
      @archive.close
    end

    # Alias for new
    def self.open(file)
      new(file)
    end

    # Tests if a given archive is a valid ALD package
    #
    # file - a Zip::File instance for the package
    # definition - an ALD::Definition instance the package must meet
    #
    # Returns true if it is valid, false otherwise
    def self.valid?(file, definition)
      true
    end
  end
end