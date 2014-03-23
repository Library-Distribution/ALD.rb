require 'nokogiri'
require_relative 'exceptions'

module ALD
  # Public: Access information in ALD package definition files.
  class Definition
    # Internal: Path to the file containing the XML Schema Definition used for
    # definition validation.
    SCHEMA_FILE = "#{File.dirname(__FILE__)}/schema.xsd"

    # Internal: The XML namespace used by the definitions.
    XML_NAMESPACE = 'ald://package/schema/2014'

    # Internal: The XML Schema instance used for validation
    #
    # Returns the Nokogiri::XML::Schema instance representing ::SCHEMA_FILE.
    def self.schema
      @schema ||= Nokogiri::XML::Schema(File.read(SCHEMA_FILE))
    end

    # Internal: The array of attributes which are defined in the root element
    # of a definition. Each of these gets a dynamically defined method.
    TOPLEVEL_ATTRIBUTES = %w[
      id
      name
      version
      type
      summary
    ]

    # Public: Gets the ID of the item to be represented by this definition.
    #
    # Examples
    #
    #   puts "Item ID: #{definition.id}"
    #
    # Signature
    #
    #   id()

    # Public: Gets the name of the item defined by this definition.
    #
    # Examples
    #
    #   puts "The item is called '#{definition.name}'"
    #
    # Signature
    #
    #   name()

    # Public: Gets the semver version of this definition's item.
    #
    # Examples
    #
    #   puts "#{definition.name} v#{definition.version}"
    #
    # Signature
    #
    #   version()

    # Public: Gets the type of item this definition represents.
    #
    # Examples
    #
    #   puts "Item type is #{definition.type}"
    #
    # Signature
    #
    #   type()

    # Public: Gets the item's summary text.
    #
    # Examples
    #
    #   puts "\n#{definition.summary}\n"
    #
    # Signature
    #
    #   summary()

    TOPLEVEL_ATTRIBUTES.each do |attr|
      define_method attr.to_sym do
        @document.xpath("//@ald:#{attr}", 'ald' => XML_NAMESPACE)[0].value
      end
    end

    # Public: Open a new definition file for analysis.
    #
    # source - the source to read the definition from. This can be a
    #          Nokogiri::XML::Document, a String or any object that responds to
    #          #read and #close.
    #
    # Examples
    #
    #   definition = ALD::Definition.new('/path/to/def.xml')
    #
    # Raises ALD::InvalidDefinitionError if the supplied source is not a valid
    # ALD package definition.
    def initialize(source)
      if source.is_a? Nokogiri::XML::Document
        @document = source
      else
        @document = Nokogiri::XML(source) { |config| config.nonet }
      end

      raise InvalidDefinitionError unless valid?
    end

    # Public: Get the defined item's description.
    #
    # Returns the description String.
    def description
      @document.xpath("//ald:description", 'ald' => XML_NAMESPACE)[0].text
    end

    # Public: Get the defined item's tags.
    #
    # Examples
    #
    #   definition.tags.each { |tag| puts " - #{tag}" }
    #
    # Returns the Array of Strings that the item is tagged with.
    def tags
      @document.xpath("//ald:tags/ald:tag/@ald:name", 'ald' => XML_NAMESPACE).map { |tag| tag.value }
    end

    # Public: Get the item's authors information
    #
    # Examples
    #
    #   definition.authors.each do |author|
    #     puts "Author: #{author['name']}"
    #     puts "\tUser name: #{author['user-name'] || '(unknown)'}"
    #     puts "\tHomepage:  #{author['homepage']  || '(unknown)'}"
    #     puts "\tEmail:     #{author['email']     || '(unknown)'}"
    #   end
    #
    # Returns an Array of Hashes, where each Hash has the 'name' key and *may*
    # also have 'user-name', 'homepage' and 'email' keys.
    def authors
      attribute_hash '//ald:authors/ald:author', %w[name user-name homepage email]
    end

    # Public: Gets additional links this definition references
    #
    # Returns an Array of Hashes, where each Hash has the keys 'name', 'href'
    # and 'description'-
    def links
     attribute_hash '//ald:links/ald:link', %w[name description href]
    end

    # Internal: Check if the definition is valid.
    # Library consumers need not call this, as ::new already does.
    #
    # Returns true, if the definition is valid according to the schema, false
    # otherwise.
    def valid?
      Definition.schema.valid?(@document)
    end

    # Public: Get the XML string representing the definition
    def to_s
      @document.to_s
    end

    private

    # Internal: Get an Array of attribute Hashes from a list of elements in the
    # definition.
    #
    # xpath - the XPath String pointing to the XML elements in the definition
    # keys  - the Array of keys to retrieve from the elements
    #
    # Returns an Array of Hashes, where each Hash has all those of the given
    # keys that were actual attributes on the relevant element.
    def attribute_hash(xpath, keys)
      @document.xpath(xpath, 'ald' => XML_NAMESPACE).map do |e|
        Hash[keys.map { |k| e.attribute_with_ns(k, XML_NAMESPACE) }.reject(&:nil?).map { |a| [a.node_name, a.value] }]
      end
    end
  end
end