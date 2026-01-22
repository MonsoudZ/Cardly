require 'rails_helper'

RSpec.describe Tag, type: :model do
  let(:user) { create(:user) }

  describe "validations" do
    it "is valid with valid attributes" do
      tag = build(:tag, user: user)
      expect(tag).to be_valid
    end

    it "requires a name" do
      tag = build(:tag, user: user, name: nil)
      expect(tag).not_to be_valid
    end

    it "requires name to be unique per user" do
      create(:tag, user: user, name: "Groceries")
      duplicate = build(:tag, user: user, name: "groceries")
      expect(duplicate).not_to be_valid
    end

    it "allows same name for different users" do
      other_user = create(:user)
      create(:tag, user: user, name: "Groceries")
      other_tag = build(:tag, user: other_user, name: "Groceries")
      expect(other_tag).to be_valid
    end

    it "sets a default color if none provided" do
      tag = create(:tag, user: user, color: nil)
      expect(tag.color).to be_present
    end
  end

  describe "associations" do
    it "belongs to a user" do
      tag = create(:tag, user: user)
      expect(tag.user).to eq(user)
    end

    it "has many gift cards through gift_card_tags" do
      tag = create(:tag, user: user)
      brand = create(:brand)
      gift_card = create(:gift_card, user: user, brand: brand)
      create(:gift_card_tag, tag: tag, gift_card: gift_card)

      expect(tag.gift_cards).to include(gift_card)
    end
  end

  describe "scopes" do
    it "orders alphabetically" do
      z_tag = create(:tag, user: user, name: "Zebra")
      a_tag = create(:tag, user: user, name: "Apple")

      expect(Tag.alphabetical.first).to eq(a_tag)
      expect(Tag.alphabetical.last).to eq(z_tag)
    end
  end

  describe "#card_count" do
    it "returns the number of gift cards with this tag" do
      tag = create(:tag, user: user)
      brand = create(:brand)
      2.times do
        gift_card = create(:gift_card, user: user, brand: brand)
        create(:gift_card_tag, tag: tag, gift_card: gift_card)
      end

      expect(tag.card_count).to eq(2)
    end
  end

  describe "#total_balance" do
    it "returns the sum of all tagged card balances" do
      tag = create(:tag, user: user)
      brand = create(:brand)

      gift_card1 = create(:gift_card, user: user, brand: brand, balance: 50)
      gift_card2 = create(:gift_card, user: user, brand: brand, balance: 75)
      create(:gift_card_tag, tag: tag, gift_card: gift_card1)
      create(:gift_card_tag, tag: tag, gift_card: gift_card2)

      expect(tag.total_balance).to eq(125)
    end
  end

  describe "name normalization" do
    it "titleizes the name" do
      tag = create(:tag, user: user, name: "grocery shopping")
      expect(tag.name).to eq("Grocery Shopping")
    end

    it "strips whitespace" do
      tag = create(:tag, user: user, name: "  groceries  ")
      expect(tag.name).to eq("Groceries")
    end
  end
end
