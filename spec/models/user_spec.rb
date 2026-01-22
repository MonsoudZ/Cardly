require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end
  end

  describe "associations" do
    it "has many gift_cards" do
      user = create(:user)
      create(:gift_card, user: user)
      expect(user.gift_cards.count).to eq(1)
    end

    it "has many listings" do
      expect(User.new).to respond_to(:listings)
    end

    it "destroys gift_cards when destroyed" do
      user = create(:user)
      create(:gift_card, user: user)
      expect { user.destroy }.to change(GiftCard, :count).by(-1)
    end
  end

  describe "#wallet_balance" do
    it "calculates correctly" do
      user = create(:user)
      brand = create(:brand)
      create(:gift_card, user: user, brand: brand, balance: 50.00, status: "active")
      create(:gift_card, user: user, brand: brand, balance: 25.00, status: "active")
      create(:gift_card, :used, user: user, brand: brand)

      expect(user.wallet_balance).to eq(75.00)
    end
  end

  describe "#total_cards_count" do
    it "returns gift card count" do
      user = create(:user)
      brand = create(:brand)
      create_list(:gift_card, 3, user: user, brand: brand)
      expect(user.total_cards_count).to eq(3)
    end
  end

  describe "#active_cards" do
    it "returns cards with balance and active status" do
      user = create(:user)
      brand = create(:brand)
      active_card = create(:gift_card, user: user, brand: brand, status: "active", balance: 50.00)
      create(:gift_card, :used, user: user, brand: brand)

      expect(user.active_cards).to include(active_card)
      expect(user.active_cards.count).to eq(1)
    end
  end

  describe "#display_name" do
    it "returns name when present" do
      user = build(:user, name: "John Doe")
      expect(user.display_name).to eq("John Doe")
    end

    it "returns email prefix when name is blank" do
      user = build(:user, name: nil, email: "john@example.com")
      expect(user.display_name).to eq("john")
    end
  end
end
