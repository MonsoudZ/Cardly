require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = users(:one)
    assert user.valid?
  end

  test "has many gift_cards" do
    user = users(:one)
    assert_respond_to user, :gift_cards
    assert user.gift_cards.count > 0
  end

  test "has many listings" do
    user = users(:one)
    assert_respond_to user, :listings
  end

  test "wallet_balance calculates correctly" do
    user = users(:one)
    expected = user.gift_cards.active.with_balance.sum(:balance)
    assert_equal expected, user.wallet_balance
  end

  test "total_cards_count returns gift card count" do
    user = users(:one)
    assert_equal user.gift_cards.count, user.total_cards_count
  end

  test "active_cards returns cards with balance and active status" do
    user = users(:one)
    active = user.active_cards
    assert active.all? { |c| c.status == "active" && c.balance > 0 }
  end

  test "display_name returns name when present" do
    user = users(:one)
    assert_equal "Test User One", user.display_name
  end

  test "display_name returns email prefix when name blank" do
    user = users(:one)
    user.name = nil
    assert_equal "user_one", user.display_name
  end

  test "destroying user destroys gift_cards" do
    user = users(:one)
    card_count = user.gift_cards.count

    assert_difference("GiftCard.count", -card_count) do
      user.destroy
    end
  end
end
