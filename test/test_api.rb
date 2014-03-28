require 'helper'
require 'json'

class ApiTest < APITestCase
  def test_invalid_auth
    invalid_auths = [nil, {}, { name: 'user' }, { password: 'pw' }]
    invalid_auths.each do |auth|
      assert_raise ArgumentError, "Failed to raise exception on invalid authentication data" do
        api.auth = auth
      end
    end
  end

  def test_valid_auth
    auth = { name: 'test', password: 'password' }
    assert_nothing_raised "Failed to set auth data to valid hash" do
      api.auth = auth
    end
    assert_equal auth, api.auth, "Failed to retrieve valid auth"
  end

  def test_version
    stub('version', JSON.generate('version' => '4.5.0-pre'))

    assert_equal '4.5.0-pre', api.version
  end
end