require "test_helper"

class MarketplaceControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get marketplace_url
    assert_response :success
  end

  test "should get sales" do
    get marketplace_sales_url
    assert_response :success
  end

  test "should get trades" do
    get marketplace_trades_url
    assert_response :success
  end

  test "should display listings" do
    get marketplace_url
    assert_response :success
    assert_select "h1", "Marketplace"
  end
end
