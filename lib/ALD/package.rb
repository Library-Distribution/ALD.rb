require 'zip'
require_relative 'definition'
require_relative 'exceptions'

module ALD
  # Public: Represents an ALD package file containing an app or library and its
  # definition.
  class Package

    # Internal: The rubyzip Zip::File object containing the data.
    attr_reader :archive

    # Public: The ALD::Definition instance representing the definition contained
    # in the package. Use this to extract all the information on the package.
    attr_reader :definition

    # Public: Opens a new ALD package file.
    #
    # file - a String representing the path to the file or a Zip::File instance
    #
    # Returns a new ALD::Package instance representing the package file
    #
    # Raises ALD::NoDefinitionError if the package contains no definition file.
    #
    # Raises ALD::InvalidPackageError if the package is not valid according to
    # its definition.
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

      # todo: file access
    end

    # Public: Closes a no longer required package. While this method has little
    # effect for now, calling it should be considered best practice and ensures
    # forward-compatibility.
    #
    # Returns nothing.
    def close
      @archive.close
    end

    # Public: Alias for ::new
    def self.open(file)
      new(file)
    end

    # Public: Tests if a given archive is a valid ALD package. Although part of
    # the public API, most library consumers will not need to call it, as it is
    # already called by ::new.
    #
    # Not yet implemented.
    #
    # file       - a Zip::File instance for the package
    # definition - an ALD::Definition instance the package must meet
    #
    # Returns true if it is valid, false otherwise
    def self.valid?(file, definition)
      true # todo
    end
  end
end