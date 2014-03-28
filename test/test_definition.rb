require 'helper'
require 'nokogiri'

class DefinitionTest < Test::Unit::TestCase
  def setup
    @definition = ALD::Definition.new(File.read('test/data/archives/valid/definition.ald'))
  end

  def test_from_doc
    doc = Nokogiri::XML(File.read('test/data/archives/valid/definition.ald'))
    definition = ALD::Definition.new(doc)
    assert_not_nil definition, "Failed to create definition from Nokogiri::XML::Document"
    assert_equal '7fa97a01c5e94ab69be4e0fe6c93a39e', definition.id.downcase
  end

  def test_attributes
    %w[id name version type summary].each { |m| assert_respond_to @definition, m.to_sym, "Definition does not respond to #{m}" }

    assert_equal '7fa97a01c5e94ab69be4e0fe6c93a39e', @definition.id.downcase, "Failed to read ID from definition"
    assert_equal 'valid-lib',                        @definition.name,        "Failed to read name from definition"
    assert_equal '1.0.0',                            @definition.version,     "Failed to read version from definition"
    assert_equal 'lib',                              @definition.type,        "Failed to read type from definition"
    assert_equal 'Some ALD item',                    @definition.summary,     "Failed to read summary from definition"
  end

  def test_description
    assert_equal 'Some ALD item for testing >>>',   @definition.description,  "Failed to read description from definition"
  end

  def test_tags
    assert_equal ['my_tag'],                        @definition.tags,         "Failed to read tags from definition"
  end

  def test_authors
    expected_authors = [{'name' => 'Oscar'}, {'name' => 'Tom', 'homepage' => 'http://lmgtfy.com/?q=tom'}, {'name' => 'Bill', 'user-name' => 'bill'}]
    assert_equal expected_authors,                  @definition.authors,      "Failed to read authors from definition"
  end

  def test_links
    expected_links = [{'name' => 'issue tracker', 'description' => 'github issue tracker', 'href' => 'https://github.com/octocat/Spoon-Knife/issues'}]
    assert_equal expected_links,                    @definition.links,        "Failed to read links from definition"
  end
end