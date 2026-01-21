require "test_helper"

class MarketplaceControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get marketplace_url
    assert_response :success
  end

  test "should filter by card_type" do
    get marketplace_url, params: { card_type: "pokemon" }
    assert_response :success
  end

  test "should display items for sale" do
    get marketplace_url
    assert_response :success
    # The page should load successfully even with no items
  end

  test "should display items for trade" do
    get marketplace_url
    assert_response :success
  end
end
