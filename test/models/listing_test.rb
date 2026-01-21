require "test_helper"

class ListingTest < ActiveSupport::TestCase
  test "valid sale listing" do
    listing = listings(:sale_listing)
    assert listing.valid?
  end

  test "valid trade listing" do
    listing = listings(:trade_listing)
    assert listing.valid?
  end

  test "requires listing_type" do
    listing = listings(:sale_listing)
    listing.listing_type = nil
    assert_not listing.valid?
    assert_includes listing.errors[:listing_type], "can't be blank"
  end

  test "listing_type must be valid" do
    listing = listings(:sale_listing)
    listing.listing_type = "invalid"
    assert_not listing.valid?
  end

  test "sale listing requires asking_price" do
    listing = listings(:sale_listing)
    listing.asking_price = nil
    assert_not listing.valid?
    assert_includes listing.errors[:asking_price], "can't be blank"
  end

  test "asking_price must be positive for sale listings" do
    listing = listings(:sale_listing)
    listing.asking_price = 0
    assert_not listing.valid?
    assert_includes listing.errors[:asking_price], "must be greater than 0"
  end

  test "trade listing requires trade_preferences" do
    listing = listings(:trade_listing)
    listing.trade_preferences = nil
    assert_not listing.valid?
    assert_includes listing.errors[:trade_preferences], "can't be blank"
  end

  test "sale? returns true for sale listings" do
    listing = listings(:sale_listing)
    assert listing.sale?
    assert_not listing.trade?
  end

  test "trade? returns true for trade listings" do
    listing = listings(:trade_listing)
    assert listing.trade?
    assert_not listing.sale?
  end

  test "active? returns true for active listings" do
    listing = listings(:sale_listing)
    assert listing.active?
  end

  test "active scope returns only active listings" do
    active = Listing.active
    assert active.include?(listings(:sale_listing))
  end

  test "for_sale scope returns sale listings" do
    sales = Listing.for_sale
    assert sales.include?(listings(:sale_listing))
    assert_not sales.include?(listings(:trade_listing))
  end

  test "for_trade scope returns trade listings" do
    trades = Listing.for_trade
    assert trades.include?(listings(:trade_listing))
    assert_not trades.include?(listings(:sale_listing))
  end

  test "savings calculates correctly for sale listings" do
    listing = listings(:sale_listing)
    expected = listing.gift_card.balance - listing.asking_price
    assert_equal expected, listing.savings
  end

  test "brand delegation works" do
    listing = listings(:sale_listing)
    assert_equal "Starbucks", listing.brand_name
  end

  test "cancel! updates status" do
    listing = listings(:sale_listing)
    listing.cancel!
    assert_equal "cancelled", listing.status
  end
end
