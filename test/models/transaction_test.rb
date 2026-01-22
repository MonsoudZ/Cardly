require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  def setup
    @buyer = users(:one)
    @seller = users(:two)
    @sale_listing = listings(:sale_listing)
    @trade_listing = listings(:trade_listing)
    @amazon_card = gift_cards(:amazon_card)
  end

  test "valid sale transaction" do
    transaction = Transaction.new(
      buyer: @buyer,
      seller: @seller,
      listing: @sale_listing,
      transaction_type: "sale",
      amount: 90.00
    )
    assert transaction.valid?
  end

  test "valid trade transaction" do
    transaction = Transaction.new(
      buyer: @buyer,
      seller: @seller,
      listing: @trade_listing,
      transaction_type: "trade",
      offered_gift_card: @amazon_card
    )
    assert transaction.valid?
  end

  test "sale requires amount" do
    transaction = Transaction.new(
      buyer: @buyer,
      seller: @seller,
      listing: @sale_listing,
      transaction_type: "sale",
      amount: nil
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:amount], "can't be blank"
  end

  test "trade requires offered gift card" do
    transaction = Transaction.new(
      buyer: @buyer,
      seller: @seller,
      listing: @trade_listing,
      transaction_type: "trade",
      offered_gift_card: nil
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:offered_gift_card], "can't be blank"
  end

  test "buyer cannot be seller" do
    transaction = Transaction.new(
      buyer: @seller,
      seller: @seller,
      listing: @sale_listing,
      transaction_type: "sale",
      amount: 90.00
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:buyer], "cannot purchase their own listing"
  end

  test "offered card must belong to buyer" do
    transaction = Transaction.new(
      buyer: @buyer,
      seller: @seller,
      listing: @trade_listing,
      transaction_type: "trade",
      offered_gift_card: gift_cards(:listed_card) # belongs to seller, not buyer
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:offered_gift_card], "must belong to you"
  end

  test "sale? returns true for sale transactions" do
    transaction = transactions(:pending_sale)
    assert transaction.sale?
    assert_not transaction.trade?
  end

  test "trade? returns true for trade transactions" do
    transaction = transactions(:pending_trade)
    assert transaction.trade?
    assert_not transaction.sale?
  end

  test "pending? returns true for pending transactions" do
    transaction = transactions(:pending_sale)
    assert transaction.pending?
  end

  test "accept! completes a sale transaction" do
    transaction = transactions(:pending_sale)
    original_owner = transaction.listing.gift_card.user

    assert transaction.accept!
    assert transaction.completed?

    # Reload and verify ownership transferred
    transaction.listing.gift_card.reload
    assert_equal transaction.buyer, transaction.listing.gift_card.user
    assert_not_equal original_owner, transaction.listing.gift_card.user
  end

  test "reject! changes status to rejected" do
    transaction = transactions(:pending_sale)
    assert transaction.reject!
    assert_equal "rejected", transaction.status
  end

  test "cancel! changes status to cancelled" do
    transaction = transactions(:pending_sale)
    assert transaction.cancel!
    assert_equal "cancelled", transaction.status
  end

  test "cannot accept non-pending transaction" do
    transaction = transactions(:pending_sale)
    transaction.update!(status: "rejected")
    assert_not transaction.accept!
  end
end
