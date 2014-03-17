require 'test/unit'
require 'ALD/package'
require 'zip'

class PackageTest < Test::Unit::TestCase
  BASE_PATH = "test/data/archives"

  def test_no_definition
    assert_raise ALD::NoDefinitionError, "Failed to recognize package without definition as invalid" do
      ALD::Package.open("#{BASE_PATH}/no_definition.zip")
    end
  end

  def test_valid
    assert_nothing_raised "Unexpected error when opening valid package" do
      package = ALD::Package.open("#{BASE_PATH}/valid.zip")
      package.close
    end
  end

  def test_from_zip
    zip = Zip::File.open("#{BASE_PATH}/valid.zip")
    assert_nothing_raised "Unexpected error when opening from Zip::File object" do
      package = ALD::Package.open(zip)
      package.close
    end
  end
end