require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should redirect to sign in when not authenticated" do
    get profile_url
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "should get show when authenticated" do
    sign_in @user
    get profile_url
    assert_response :success
    assert_select "h1", @user.email
  end

  test "should get edit when authenticated" do
    sign_in @user
    get edit_profile_url
    assert_response :success
    assert_select "h1", "Edit Profile"
  end

  test "should update profile with valid data" do
    sign_in @user
    patch profile_url, params: { user: { name: "Test User", bio: "I love collecting cards!" } }
    assert_redirected_to profile_path

    @user.reload
    assert_equal "Test User", @user.name
    assert_equal "I love collecting cards!", @user.bio
  end

  test "should show name after update" do
    sign_in @user
    @user.update!(name: "Card Collector")
    get profile_url
    assert_response :success
    assert_select "h1", "Card Collector"
  end

  test "should show bio after update" do
    sign_in @user
    @user.update!(bio: "Passionate about Pokemon cards")
    get profile_url
    assert_response :success
    assert_select "p.text-sm.text-gray-700", "Passionate about Pokemon cards"
  end

  test "should reject bio longer than 500 characters" do
    sign_in @user
    long_bio = "a" * 501
    patch profile_url, params: { user: { bio: long_bio } }
    assert_response :unprocessable_entity
  end

  test "should reject name longer than 100 characters" do
    sign_in @user
    long_name = "a" * 101
    patch profile_url, params: { user: { name: long_name } }
    assert_response :unprocessable_entity
  end
end
