require 'rexml/document'
require 'ALD/exceptions'

module ALD
  class Definition
    attr_reader :document

    def initialize(source)
      if source.is_a? REXML::Document
        @document = source
      else
        @document = REXML::Document.new(source)
      end
      unless valid?
        raise InvalidDefinitionError
      end
    end

    def self.create!(generator)
    end

    def valid?
      true
    end
  end
end