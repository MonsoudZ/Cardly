require "test_helper"

class CardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @card = cards(:pikachu)
  end

  test "should get index" do
    get cards_url
    assert_response :success
  end

  test "should filter by card_type" do
    get cards_url, params: { card_type: "pokemon" }
    assert_response :success
  end

  test "should filter by set_name" do
    get cards_url, params: { set_name: "Base Set" }
    assert_response :success
  end

  test "should filter by rarity" do
    get cards_url, params: { rarity: "rare" }
    assert_response :success
  end

  test "should show card" do
    get card_url(@card)
    assert_response :success
  end
end
