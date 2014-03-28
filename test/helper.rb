require 'coveralls'
Coveralls.wear!

require 'test/unit'
require 'ALD'
require 'webmock/test_unit'

class APITestCase < Test::Unit::TestCase
  API_URL = 'http://localhost/'

  def api
    @api ||= ALD::API.new(API_URL)
  end

  def stub(url, data, method = :get, query = {})
    if url.is_a?(Regexp)
      url = /^#{Regexp.escape(API_URL)}#{url}/
    else
      url = API_URL + url
    end
    stub_request(method, url).with(query: hash_including(query)).to_return do |request|
      generated_data = block_given? ? yield(request, data) : data
      if generated_data.is_a?(Hash)
        generated_data
      else
        { status: 200, headers: { 'Content-type' => 'application/json' }, body: generated_data }
      end
    end
  end
end