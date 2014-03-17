require 'test/unit'
require 'ALD'

class DefinitionTest < Test::Unit::TestCase
  def package
    @package ||= ALD::Package.open("test/data/archives/valid.zip")
  end

  def test_attributes
    %w[id name version type summary].each { |m| assert_respond_to package.definition, m.to_sym }

    assert_equal '7fa97a01c5e94ab69be4e0fe6c93a39e', package.definition.id.downcase, "Failed to read ID from definition"
    assert_equal 'valid-lib', package.definition.name
    assert_equal '1.0.0', package.definition.version
    assert_equal 'lib', package.definition.type
    assert_equal 'Some ALD item', package.definition.summary
  end
end