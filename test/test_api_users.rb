require 'helper'
require 'json'

class TestApiUsers < APITestCase
  USER_ID_REGEX = /users\/([0-9a-fA-F]{32})\/?$/

  USER_NAME_REGEX = /users\/(.+)\/?$/

  def setup
    stub('users/', JSON.generate(self.user_data))
    stub(USER_NAME_REGEX, self.user_data) do |request, user_data|
      match = USER_NAME_REGEX.match(request.uri.to_s)
      JSON.generate(user_data.find { |user| user[:name] == match[1] })
    end
    stub(USER_ID_REGEX, self.user_data) do |request, user_data|
      match = USER_ID_REGEX.match(request.uri.to_s)
      JSON.generate(user_data.find { |user| /#{match[1]}/i =~ user[:id] })
    end
  end

  def user_data
    @user_data ||= [
      { name: 'Bob',  id: '4591f82a455144ebbaa62f5e642283b6' },
      { name: 'Fred', id: '5a036c623443483989878fc8884d9acc' }
    ]
  end

  def test_empty_users
    stub('users/', '[]')

    assert_not_nil api.users, "Empty list of all users is nil"
    assert_equal ALD::API::UserCollection, api.users.class, "Empty user list is no UserCollection"
    assert_equal 0, api.users.count, "Empty user list doesn't have count 0"
  end

  def test_all_users
    assert_equal user_data.count, api.users.count, "API#users#count is not correct"
    api.users.each_with_index do |user, i|
      assert_equal ALD::API::User, user.class, "Entry in API#users is not ALD::API::User"
      assert_equal user_data[i][:name], user.name, "User #{i} in API#users is not the expected #{user_data[i][:name]}"
    end
  end

  def test_get_user_by_id
    id = api.normalize_id(user_data[0][:id])
    [api.user(id), api.users[id]].each do |user|
      assert_equal ALD::API::User, user.class, "User retrieved by ID is not an API::User"
      assert_equal 'Bob', user.name, "User retrieved by ID has wrong name"
    end
  end

  def test_get_user_by_unnormalized_id
    id = user_data[1][:id]
    [api.user(id), api.users[id]].each do |user|
      assert_equal ALD::API::User, user.class, "User retrieved by unnormalized ID is not an API::User"
      assert_equal 'Fred', user.name, "User retrieved by unnormalized ID has wrong name"
    end
  end

  def test_get_user_by_name
    [api.user('Bob'), api.users['Bob']].each do |user|
      assert_equal ALD::API::User, user.class, "User retrieved by name is not an API::User"
      assert_equal 'Bob', user.name, "User retrieved by name has wrong name"
    end
  end
end