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
      query = request.uri.query_values || {}

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
    stub_request(:get, /^#{Regexp.escape(API_URL)}items\/([0-9a-fA-F]{32})\/?$/).to_return do |request|
      /items\/([0-9a-fA-F]{32})\/?$/ =~ request.uri.to_s
      { status: 200, headers: { 'Content-type' => 'application/json' }, body: JSON.generate(item_data.find { |item| item[:id] =~ /#{$~[1]}/i }) }
    end
    stub_request(:get, /^#{Regexp.escape(API_URL)}items\/([\w_]+)\/(.+)\/?$/).to_return do |request|
      /items\/([\w_]+)\/(.+)\/?$/ =~ request.uri.to_s
      { status: 200, headers: { 'Content-type' => 'application/json' }, body: JSON.generate(item_data.find { |item| item[:name] == $~[1] && item[:version] == $~[2] }) }
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
    assert_equal 'B86EE43BD2FB40C6958C031D2F3BAE6A', api.item('TestItem', '1.0.0').id, "API#item(name, version) returned wrong item"
    assert_equal 'DE4E651033D64CA39FDB3761F34CECEA', api.items['TestItem', '0.0.1'].id, "ItemCollection#[name, version] returned wrong item"
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

  def test_where_sort_local
    api.items[0] # force request
    assert_requested(@stub, times: 1) # make sure it was requested

    # real test starts here:
    assert_equal '2.3.4', api.items(sort: { version: :desc }).first.version, "API#items returned wrong version sorting"
    assert_requested(@stub, times: 1) # sorting was done locally

    assert_equal 'OtherItem', api.items(sort: [:name]).first.name, "API#items returned wrong name sorting"
    assert_requested(@stub, times: 1) # sorting was done locally
  end

  def test_where_range
    items = api.items(range: (1..2)).where(range: (1..1))
    assert_equal 1, items.count, "ItemCollection#where returned empty collection for :range"
    assert_equal api.items[2], items[0], "ItemCollection#where with :range returned the wrong item"
  end
end