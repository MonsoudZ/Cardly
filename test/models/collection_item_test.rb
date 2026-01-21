require "test_helper"

class CollectionItemTest < ActiveSupport::TestCase
  test "valid collection_item" do
    item = collection_items(:pikachu_item)
    assert item.valid?
  end

  test "requires quantity" do
    item = CollectionItem.new(collection: collections(:pokemon_collection), card: cards(:black_lotus))
    item.quantity = nil
    assert_not item.valid?
    assert_includes item.errors[:quantity], "can't be blank"
  end

  test "quantity must be positive" do
    item = CollectionItem.new(collection: collections(:pokemon_collection), card: cards(:black_lotus), quantity: 0)
    assert_not item.valid?
    assert_includes item.errors[:quantity], "must be greater than 0"
  end

  test "validates condition inclusion" do
    item = CollectionItem.new(
      collection: collections(:pokemon_collection),
      card: cards(:black_lotus),
      quantity: 1,
      condition: "invalid"
    )
    assert_not item.valid?
    assert_includes item.errors[:condition], "is not included in the list"
  end

  test "allows blank condition" do
    item = CollectionItem.new(
      collection: collections(:pokemon_collection),
      card: cards(:black_lotus),
      quantity: 1,
      condition: ""
    )
    assert item.valid?
  end

  test "validates acquired_price is not negative" do
    item = CollectionItem.new(
      collection: collections(:pokemon_collection),
      card: cards(:black_lotus),
      quantity: 1,
      acquired_price: -10
    )
    assert_not item.valid?
    assert_includes item.errors[:acquired_price], "must be greater than or equal to 0"
  end

  test "validates asking_price is not negative" do
    item = CollectionItem.new(
      collection: collections(:pokemon_collection),
      card: cards(:black_lotus),
      quantity: 1,
      asking_price: -10
    )
    assert_not item.valid?
    assert_includes item.errors[:asking_price], "must be greater than or equal to 0"
  end

  test "card must be unique in collection" do
    existing = collection_items(:pikachu_item)
    duplicate = CollectionItem.new(
      collection: existing.collection,
      card: existing.card,
      quantity: 1
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:card_id], "already exists in this collection"
  end

  test "total_value calculates correctly" do
    item = collection_items(:pikachu_item)
    expected = (item.card.estimated_value || 0) * item.quantity
    assert_equal expected, item.total_value
  end

  test "display_condition titleizes condition" do
    item = collection_items(:pikachu_item)
    assert_equal "Mint", item.display_condition
  end

  test "for_trade scope" do
    tradeable = CollectionItem.for_trade
    assert tradeable.all?(&:for_trade?)
  end

  test "for_sale scope" do
    for_sale = CollectionItem.for_sale
    assert for_sale.all?(&:for_sale?)
  end

  test "delegates card attributes" do
    item = collection_items(:pikachu_item)
    assert_equal item.card.name, item.card_name
    assert_equal item.card.card_type, item.card_card_type
  end
end
