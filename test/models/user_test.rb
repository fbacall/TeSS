require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  setup do
    mock_images
    @user_data = users(:regular_user)
    # regular_user is already saved so make username and email unique
    @user_data.username = "0#{@user_data.username}"
    @user_data.email = "0#{@user_data.email}"
    User.get_default_user
  end

  test 'should save new user' do
    user = User.new(username: @user_data.username, password: @user_data.encrypted_password, email: @user_data.email)
    assert user.save, 'Did not save user'
  end

  test 'should set default role after saving new user' do
    user = User.new(username: @user_data.username, password: @user_data.encrypted_password, email: @user_data.email)
    assert_not_instance_of Role, user.role
    user.save
    assert_instance_of Role, user.role
  end

  test 'should set default profile after saving new user' do
    user = User.new(username: @user_data.username, password: @user_data.encrypted_password, email: @user_data.email)
    assert_not_instance_of Profile, user.profile
    user.save
    assert_instance_of Profile, user.profile
    assert_equal user.profile.user, user
  end

  test 'should not save user without nil_email' do
    user = User.new(username: @user_data.username, password: @user_data.encrypted_password, email: nil)
    assert_not user.save, 'Saved user with nil e-mail address field'
  end

  test 'should not save user without empty_email' do
    user = User.new(username: @user_data.username, password: @user_data.encrypted_password, email: '')
    assert_not user.save, 'Saved user with empty e-mail address field'
  end

  test 'should not save user without valid_email format' do
    user = User.new(username: @user_data.username, password: @user_data.encrypted_password, email: 'horse')
    assert_not user.save, 'Saved user with invalid e-mail address'
  end

  test 'should not save with nil password' do
    user = User.new(username: @user_data.username, password: nil, email: @user_data.email)
    assert_not user.save, 'Saved user with no password'
  end

  test 'should not save with password under 8 characters' do
    user = User.new(username: @user_data.username, password: '1234567', email: @user_data.email)
    assert_not user.save, 'Allowed a user to have a password under 8 characters'
    user = User.new(username: @user_data.username, password: '12345678', email: @user_data.email)
    assert user.save, 'Did not save with correct length password'
  end

  test 'should not save two users with same username' do
    user1 = User.new(username: @user_data.username, password: @user_data.encrypted_password, email: "#{@user_data.email}2")
    user2 = User.new(username: @user_data.username, password: @user_data.encrypted_password, email: "#{@user_data.email}1")
    assert user1.save, 'Did not save the first user'
    assert_not user2.save, 'Saved the second user with same username as first'
  end

  test 'should not save two users with same email' do
    user1 = User.new(username: "#{@user_data.username}1", password: @user_data.encrypted_password, email: @user_data.email)
    user2 = User.new(username: "#{@user_data.username}2", password: @user_data.encrypted_password, email: @user_data.email)
    assert user1.save, 'Did not save the first user'
    assert_not user2.save, 'Saved a second user with same e-mail address'
  end

  test 'should destroy user' do
    user = users(:regular_user)
    assert_difference('User.count', -1) do
      user.destroy
    end
  end
end
