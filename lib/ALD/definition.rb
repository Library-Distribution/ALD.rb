require 'rexml/document'
require 'ALD/exceptions'

module ALD
  class Definition
    attr_reader :document

    XML_NAMESPACE = 'ald://package/schema/2012'

    TOPLEVEL_ATTRIBUTES = %w[
      id
      name
      version
      type
      summary
    ]

    TOPLEVEL_ATTRIBUTES.each do |attr|
      define_method attr.to_sym do
        REXML::XPath.match(document.root, "//@ald:#{attr}", 'ald' => XML_NAMESPACE)[0].value
      end
    end

    def initialize(source)
      if source.is_a? REXML::Document
        @document = source
      else
        @document = REXML::Document.new(source)
      end

      raise InvalidDefinitionError unless valid?
    end

    def description
      REXML::XPath.match(document.root, "//ald:description", 'ald' => XML_NAMESPACE)[0].text
    end

    def tags
      REXML::XPath.match(document.root, "//ald:tags/ald:tag/@ald:name", 'ald' => XML_NAMESPACE).map { |tag| tag.value }
    end

    def valid?
      true
    end
  end
end