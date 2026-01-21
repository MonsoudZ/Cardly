require "test_helper"

class CollectionTest < ActiveSupport::TestCase
  test "valid collection" do
    collection = collections(:pokemon_collection)
    assert collection.valid?
  end

  test "requires name" do
    collection = Collection.new(user: users(:one))
    assert_not collection.valid?
    assert_includes collection.errors[:name], "can't be blank"
  end

  test "requires unique name per user" do
    existing = collections(:pokemon_collection)
    duplicate = Collection.new(user: existing.user, name: existing.name)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "allows same name for different users" do
    collection = Collection.new(user: users(:two), name: "My Pokemon Collection")
    assert collection.valid?
  end

  test "belongs to user" do
    collection = collections(:pokemon_collection)
    assert_equal users(:one), collection.user
  end

  test "has many collection_items" do
    collection = collections(:pokemon_collection)
    assert_respond_to collection, :collection_items
  end

  test "has many cards through collection_items" do
    collection = collections(:pokemon_collection)
    assert_respond_to collection, :cards
  end

  test "total_cards returns sum of quantities" do
    collection = collections(:pokemon_collection)
    expected = collection.collection_items.sum(:quantity)
    assert_equal expected, collection.total_cards
  end

  test "public_collections scope" do
    public_collections = Collection.public_collections
    assert public_collections.all?(&:public?)
  end

  test "private_collections scope" do
    private_collections = Collection.private_collections
    assert private_collections.none?(&:public?)
  end

  test "items_for_trade returns tradeable items" do
    collection = collections(:pokemon_collection)
    tradeable = collection.items_for_trade
    assert tradeable.all?(&:for_trade?)
  end

  test "items_for_sale returns items for sale" do
    collection = collections(:pokemon_collection)
    for_sale = collection.items_for_sale
    assert for_sale.all?(&:for_sale?)
  end
end
