require 'helper'
require 'test/unit'
require 'ALD'

class DefinitionTest < Test::Unit::TestCase
  def setup
    @package ||= ALD::Package.open("test/data/archives/valid.zip")
  end

  def teardown
    @package.close
  end

  def test_attributes
    %w[id name version type summary].each { |m| assert_respond_to @package.definition, m.to_sym, "Definition does not respond to #{m}" }

    assert_equal '7fa97a01c5e94ab69be4e0fe6c93a39e', @package.definition.id.downcase, "Failed to read ID from definition"
    assert_equal 'valid-lib',                        @package.definition.name,        "Failed to read name from definition"
    assert_equal '1.0.0',                            @package.definition.version,     "Failed to read version from definition"
    assert_equal 'lib',                              @package.definition.type,        "Failed to read type from definition"
    assert_equal 'Some ALD item',                    @package.definition.summary,     "Failed to read summary from definition"
  end

  def test_description
    assert_equal 'Some ALD item for testing >>>',   @package.definition.description,  "Failed to read description from definition"
  end

  def test_tags
    assert_equal ['my_tag'],                        @package.definition.tags,         "Failed to read tags from definition"
  end
end