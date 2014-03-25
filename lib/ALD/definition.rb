require 'nokogiri'
require 'ALD/exceptions'

module ALD
  class Definition
    SCHEMA_FILE = "#{File.dirname(__FILE__)}/schema.xsd"

    XML_NAMESPACE = 'ald://package/schema/2014'

    def self.schema
      @schema ||= Nokogiri::XML::Schema(File.read(SCHEMA_FILE))
    end

    TOPLEVEL_ATTRIBUTES = %w[
      id
      name
      version
      type
      summary
    ]

    TOPLEVEL_ATTRIBUTES.each do |attr|
      define_method attr.to_sym do
        @document.xpath("//@ald:#{attr}", 'ald' => XML_NAMESPACE)[0].value
      end
    end

    def initialize(source)
      if source.is_a? Nokogiri::XML::Document
        @document = source
      else
        @document = Nokogiri::XML(source) { |config| config.nonet }
      end

      raise InvalidDefinitionError unless valid?
    end

    def description
      @document.xpath("//ald:description", 'ald' => XML_NAMESPACE)[0].text
    end

    def tags
      @document.xpath("//ald:tags/ald:tag/@ald:name", 'ald' => XML_NAMESPACE).map { |tag| tag.value }
    end

    def authors
      attribute_hash '//ald:authors/ald:author', %w[name user-name homepage email]
    end

    def links
     attribute_hash '//ald:links/ald:link', %w[name description href]
    end

    def valid?
      Definition.schema.valid?(@document)
    end

    def to_s
      @document.to_s
    end

    private

    def attribute_hash(xpath, keys)
      @document.xpath(xpath, 'ald' => XML_NAMESPACE).map do |e|
        Hash[keys.map { |k| e.attribute_with_ns(k, XML_NAMESPACE) }.compact.map { |a| [a.node_name, a.value] }]
      end
    end
  end
end