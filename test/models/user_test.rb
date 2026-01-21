require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = users(:one)
    assert user.valid?
  end

  test "has many collections" do
    user = users(:one)
    assert_respond_to user, :collections
    assert user.collections.count > 0
  end

  test "has many collection_items through collections" do
    user = users(:one)
    assert_respond_to user, :collection_items
  end

  test "has many cards through collection_items" do
    user = users(:one)
    assert_respond_to user, :cards
  end

  test "total_collection_value calculates correctly" do
    user = users(:one)
    # This should return the sum of all card values * quantities
    assert_kind_of Numeric, user.total_collection_value
  end

  test "total_cards_count sums quantities" do
    user = users(:one)
    expected = user.collection_items.sum(:quantity)
    assert_equal expected, user.total_cards_count
  end

  test "items_for_trade returns tradeable items" do
    user = users(:one)
    tradeable = user.items_for_trade
    assert tradeable.all?(&:for_trade?)
  end

  test "items_for_sale returns items for sale" do
    user = users(:one)
    for_sale = user.items_for_sale
    assert for_sale.all?(&:for_sale?)
  end

  test "display_name returns name when present" do
    user = users(:one)
    user.name = "John Doe"
    assert_equal "John Doe", user.display_name
  end

  test "display_name returns email prefix when name blank" do
    user = users(:one)
    user.name = nil
    assert_equal user.email.split("@").first, user.display_name
  end

  test "destroying user destroys collections" do
    user = users(:one)
    collection_ids = user.collection_ids

    assert_difference("Collection.count", -user.collections.count) do
      user.destroy
    end

    collection_ids.each do |id|
      assert_nil Collection.find_by(id: id)
    end
  end
end
