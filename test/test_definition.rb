require 'helper'
require 'test/unit'
require 'ALD/definition'

class DefinitionTest < Test::Unit::TestCase
  def setup
    @definition = ALD::Definition.new(File.read('test/data/archives/valid/definition.ald'))
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
end