require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @listing = listings(:sale_listing)
  end

  test "index requires authentication" do
    get favorites_url
    assert_response :redirect
  end

  test "index shows user favorites" do
    sign_in @user
    get favorites_url
    assert_response :success
    assert_select "h1", "My Watchlist"
  end

  test "create requires authentication" do
    post listing_favorite_url(@listing)
    assert_response :redirect
  end

  test "create adds listing to favorites" do
    sign_in @user
    # First remove any existing favorite
    Favorite.where(user: @user, listing: @listing).destroy_all

    assert_difference("Favorite.count", 1) do
      post listing_favorite_url(@listing)
    end
    assert_redirected_to marketplace_url
    assert @user.favorited?(@listing)
  end

  test "create responds to turbo stream" do
    sign_in @user
    Favorite.where(user: @user, listing: @listing).destroy_all

    post listing_favorite_url(@listing), as: :turbo_stream
    assert_response :success
  end

  test "destroy requires authentication" do
    delete listing_favorite_url(@listing)
    assert_response :redirect
  end

  test "destroy removes listing from favorites" do
    sign_in @user
    Favorite.find_or_create_by!(user: @user, listing: @listing)

    assert_difference("Favorite.count", -1) do
      delete listing_favorite_url(@listing)
    end
    assert_not @user.favorited?(@listing)
  end

  test "destroy responds to turbo stream" do
    sign_in @user
    Favorite.find_or_create_by!(user: @user, listing: @listing)

    delete listing_favorite_url(@listing), as: :turbo_stream
    assert_response :success
  end

  test "empty watchlist shows browse message" do
    sign_in @user
    Favorite.where(user: @user).destroy_all

    get favorites_url
    assert_response :success
    assert_select "h3", "No favorites yet"
  end
end
