require "test_helper"

class GiftCardTest < ActiveSupport::TestCase
  test "valid gift card" do
    card = gift_cards(:amazon_card)
    assert card.valid?
  end

  test "requires balance" do
    card = gift_cards(:amazon_card)
    card.balance = nil
    assert_not card.valid?
    assert_includes card.errors[:balance], "can't be blank"
  end

  test "balance must be non-negative" do
    card = gift_cards(:amazon_card)
    card.balance = -10
    assert_not card.valid?
    assert_includes card.errors[:balance], "must be greater than or equal to 0"
  end

  test "requires original_value" do
    card = gift_cards(:amazon_card)
    card.original_value = nil
    assert_not card.valid?
    assert_includes card.errors[:original_value], "can't be blank"
  end

  test "original_value must be positive" do
    card = gift_cards(:amazon_card)
    card.original_value = 0
    assert_not card.valid?
    assert_includes card.errors[:original_value], "must be greater than 0"
  end

  test "status must be valid" do
    card = gift_cards(:amazon_card)
    card.status = "invalid"
    assert_not card.valid?
  end

  test "acquired_from must be valid" do
    card = gift_cards(:amazon_card)
    card.acquired_from = "invalid"
    assert_not card.valid?
  end

  test "active scope returns only active cards" do
    active_cards = GiftCard.active
    assert active_cards.include?(gift_cards(:amazon_card))
    assert_not active_cards.include?(gift_cards(:used_card))
  end

  test "with_balance scope returns cards with balance > 0" do
    cards = GiftCard.with_balance
    assert cards.include?(gift_cards(:amazon_card))
    assert_not cards.include?(gift_cards(:used_card))
  end

  test "expired? returns true for expired cards" do
    card = gift_cards(:amazon_card)
    card.expiration_date = 1.day.ago
    assert card.expired?
  end

  test "expired? returns false for non-expired cards" do
    card = gift_cards(:amazon_card)
    assert_not card.expired?
  end

  test "expiring_soon? returns true for cards expiring within 30 days" do
    card = gift_cards(:expiring_card)
    assert card.expiring_soon?
  end

  test "used? returns true for cards with zero balance" do
    card = gift_cards(:used_card)
    assert card.used?
  end

  test "balance_percentage calculates correctly" do
    card = gift_cards(:amazon_card)
    expected = ((75.50 / 100.00) * 100).round
    assert_equal expected, card.balance_percentage
  end

  test "masked_card_number shows last 4 digits" do
    card = gift_cards(:amazon_card)
    assert_equal "****3456", card.masked_card_number
  end

  test "masked_pin returns asterisks" do
    card = gift_cards(:amazon_card)
    assert_equal "****", card.masked_pin
  end

  test "brand delegation works" do
    card = gift_cards(:amazon_card)
    assert_equal "Amazon", card.brand_name
  end
end
