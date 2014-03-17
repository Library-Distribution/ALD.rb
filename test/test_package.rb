require 'test/unit'
require 'ALD/package'

class PackageTest < Test::Unit::TestCase
  BASE_PATH = "test/data/archives"

  def test_no_definition
    assert_raise ALD::NoDefinitionError, "Failed to recognize package without definition as invalid" do
      ALD::Package.open("#{BASE_PATH}/no_definition.ald")
    end
  end
end