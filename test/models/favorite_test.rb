require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @other_user = users(:two)
    @listing = listings(:sale_listing)
  end

  test "valid favorite" do
    favorite = Favorite.new(user: @user, listing: @listing)
    assert favorite.valid?
  end

  test "requires user" do
    favorite = Favorite.new(listing: @listing)
    assert_not favorite.valid?
    assert_includes favorite.errors[:user], "must exist"
  end

  test "requires listing" do
    favorite = Favorite.new(user: @user)
    assert_not favorite.valid?
    assert_includes favorite.errors[:listing], "must exist"
  end

  test "user cannot favorite same listing twice" do
    Favorite.create!(user: @user, listing: @listing)
    duplicate = Favorite.new(user: @user, listing: @listing)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:listing_id], "already in your watchlist"
  end

  test "different users can favorite same listing" do
    Favorite.create!(user: @user, listing: @listing)
    other_favorite = Favorite.new(user: @other_user, listing: @listing)
    assert other_favorite.valid?
  end

  test "active_listings scope returns favorites with active listings" do
    favorite = favorites(:user_one_favorite)
    assert_includes Favorite.active_listings, favorite
  end

  test "user favorited? returns true when favorite exists" do
    Favorite.create!(user: @user, listing: @listing)
    assert @user.favorited?(@listing)
  end

  test "user favorited? returns false when no favorite" do
    assert_not @other_user.favorited?(listings(:trade_listing))
  end
end
