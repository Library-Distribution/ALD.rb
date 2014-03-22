require 'helper'
require 'ALD/api'
require 'json'
require 'webmock/test_unit'

class TestApiItems < Test::Unit::TestCase
  API_URL = 'http://localhost/'

  def api
    @api ||= ALD::API.new(API_URL)
  end

  def item_data
    @item_data ||= [
      { name: 'TestItem',  version: '0.0.1', id: 'de4e651033d64ca39fdb3761f34cecea' },
      { name: 'TestItem',  version: '1.0.0', id: 'b86ee43bd2fb40c6958c031d2f3bae6a' },
      { name: 'OtherItem', version: '2.3.4', id: '8318665c44634a41bed8b795e5b11a8d' }
    ]
  end

  def setup
    @stub = stub_request(:get, API_URL + 'items/').with(query: hash_including({})).to_return do |request|
      item_data = self.item_data
      query = request.uri.query_values

      # simulate server behaviour for 'start' and 'count' params
      item_data = item_data[query['start'].to_i, item_data.length] if query.key?('start')
      item_data = item_data.take(query['count'].to_i) if query.key?('count')

      # simulate server behaviour for 'name' filter
      item_data.select! { |item| item[:name] == query['name'] } if query.key?('name')

      {
        status: 200,
        headers: { 'Content-type' => 'application/json' },
        body: JSON.generate(item_data)
      }
    end
  end

  def test_empty_items
    stub_request(:get, API_URL + 'items/').with(query: hash_including({})).to_return(
      status: 200,
      headers: { 'Content-type' => 'application/json' },
      body: '[]'
    )

    assert_not_nil api.items, "Empty list of all items is nil"
    assert_equal ALD::API::ItemCollection, api.items.class, "Empty item list is no ItemCollection"
    assert_equal 0, api.items.count, "Empty item list doesn't have count 0"
  end

  def test_all_items
    assert_equal item_data.count, api.items.count, "API#items#count is not correct"
    api.items.each_with_index do |item, i|
      assert_equal ALD::API::Item, item.class, "Entry in API#items is not ALD::API::Item"
      assert_equal item_data[i][:name], item.name, "Item #{i} in API#items is not the expected #{item_data[i][:name]}"
    end
  end

  def test_get_item_by_id
    items = [
      api.item(api.normalize_id(item_data[0][:id])),
      api.items[api.normalize_id(item_data[0][:id])]
    ]

    items.each do |item|
      assert_not_nil item, "Failed to retrieve item by ID"
      assert_equal ALD::API::Item, item.class, "Item by ID did not return ALD::API::Item"
      assert_equal item_data[0][:name], item.name, "Item by ID returned item with incorrect name"
    end
  end

  def test_get_item_by_unnormalized_id
    items = [
      api.item(item_data[0][:id]),
      api.items[item_data[0][:id]]
    ]

    items.each do |item|
      assert_not_nil item, "Failed to retrieve item by unnormalized ID"
      assert_equal ALD::API::Item, item.class, "Item by unnormalized ID did not return ALD::API::Item"
      assert_equal item_data[0][:name], item.name, "Item by unnormalized ID returned item with incorrect name"
    end
  end

  def test_get_item_by_index
    assert_equal 'TestItem', api.items[0].name, "ItemCollection#[0] returned wrong item"
    assert_equal 'OtherItem', api.items[2].name, "ItemCollection#[2] returned wrong item"
    assert_nil api.items[api.items.count], "ItemCollection#[] is not zero-based or did not return nil for not existent item"
  end

  def test_get_item_by_name_version
    assert_equal api.items[1], api.item('TestItem', '1.0.0'), "API#item(name, version) returned wrong item"
    assert_equal api.items[0], api.items['TestItem', '0.0.1'], "ItemCollection#[name, version] returned wrong item"
  end

  def test_where_name
    assert api.items(name: 'TestItem').all? { |i| i.name == 'TestItem' }, "API#items(name: ...) returned item with different name"
    assert api.items.where(name: 'TestItem').all? { |i| i.name == 'TestItem' }, "ItemCollection#where returned item with different name"
  end

  def test_where_name_local
    api.items[0] # force request
    assert_requested(@stub, times: 1) # make sure it was requested

    # real test starts here:
    assert api.items(name: 'OtherItem').all? { |i| i.name == 'OtherItem' }, "API#items returned item with different name"
    assert_requested(@stub, times: 1) # filtering was done locally
  end

  def test_where_range
    items = api.items(range: (1..2)).where(range: (1..1))
    assert_equal 1, items.count, "ItemCollection#where returned empty collection for :range"
    assert_equal api.items[2], items[0], "ItemCollection#where with :range returned the wrong item"
  end
end