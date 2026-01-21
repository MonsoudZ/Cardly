require "test_helper"

class CardTest < ActiveSupport::TestCase
  test "valid card" do
    card = cards(:pikachu)
    assert card.valid?
  end

  test "requires name" do
    card = Card.new(card_type: "pokemon")
    assert_not card.valid?
    assert_includes card.errors[:name], "can't be blank"
  end

  test "requires card_type" do
    card = Card.new(name: "Test Card")
    assert_not card.valid?
    assert_includes card.errors[:card_type], "can't be blank"
  end

  test "validates card_type inclusion" do
    card = Card.new(name: "Test", card_type: "invalid")
    assert_not card.valid?
    assert_includes card.errors[:card_type], "is not included in the list"
  end

  test "validates rarity inclusion" do
    card = Card.new(name: "Test", card_type: "pokemon", rarity: "invalid")
    assert_not card.valid?
    assert_includes card.errors[:rarity], "is not included in the list"
  end

  test "allows blank rarity" do
    card = Card.new(name: "Test", card_type: "pokemon", rarity: "")
    assert card.valid?
  end

  test "validates estimated_value is not negative" do
    card = Card.new(name: "Test", card_type: "pokemon", estimated_value: -10)
    assert_not card.valid?
    assert_includes card.errors[:estimated_value], "must be greater than or equal to 0"
  end

  test "by_type scope" do
    pokemon_cards = Card.by_type("pokemon")
    assert pokemon_cards.all? { |c| c.card_type == "pokemon" }
  end

  test "by_rarity scope" do
    rare_cards = Card.by_rarity("rare")
    assert rare_cards.all? { |c| c.rarity == "rare" }
  end
end
