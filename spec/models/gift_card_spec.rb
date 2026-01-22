require "rails_helper"

RSpec.describe GiftCard, type: :model do
  describe "validations" do
    subject { build(:gift_card) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires balance" do
      subject.balance = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:balance]).to include("can't be blank")
    end

    it "requires balance to be non-negative" do
      subject.balance = -10
      expect(subject).not_to be_valid
      expect(subject.errors[:balance]).to include("must be greater than or equal to 0")
    end

    it "requires original_value" do
      subject.original_value = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:original_value]).to include("can't be blank")
    end

    it "requires original_value to be positive" do
      subject.original_value = 0
      expect(subject).not_to be_valid
      expect(subject.errors[:original_value]).to include("must be greater than 0")
    end

    it "requires valid status" do
      subject.status = "invalid"
      expect(subject).not_to be_valid
    end

    it "requires valid acquired_from" do
      subject.acquired_from = "invalid"
      expect(subject).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:active_card) { create(:gift_card, status: "active", balance: 50.00) }
    let!(:used_card) { create(:gift_card, :used) }

    describe ".active" do
      it "returns only active cards" do
        expect(GiftCard.active).to include(active_card)
        expect(GiftCard.active).not_to include(used_card)
      end
    end

    describe ".with_balance" do
      it "returns cards with balance > 0" do
        expect(GiftCard.with_balance).to include(active_card)
        expect(GiftCard.with_balance).not_to include(used_card)
      end
    end
  end

  describe "#expired?" do
    it "returns true for expired cards" do
      card = build(:gift_card, expiration_date: 1.day.ago)
      expect(card.expired?).to be true
    end

    it "returns false for non-expired cards" do
      card = build(:gift_card, expiration_date: 1.year.from_now)
      expect(card.expired?).to be false
    end
  end

  describe "#expiring_soon?" do
    it "returns true for cards expiring within 30 days" do
      card = build(:gift_card, :expiring_soon)
      expect(card.expiring_soon?).to be true
    end

    it "returns false for cards expiring after 30 days" do
      card = build(:gift_card, expiration_date: 60.days.from_now)
      expect(card.expiring_soon?).to be false
    end
  end

  describe "#used?" do
    it "returns true for cards with zero balance" do
      card = build(:gift_card, :used)
      expect(card.used?).to be true
    end

    it "returns false for cards with balance" do
      card = build(:gift_card, balance: 50.00)
      expect(card.used?).to be false
    end
  end

  describe "#balance_percentage" do
    it "calculates correctly" do
      card = build(:gift_card, balance: 75.50, original_value: 100.00)
      expect(card.balance_percentage).to eq(76) # rounded
    end
  end

  describe "#masked_card_number" do
    it "shows last 4 digits" do
      card = build(:gift_card, card_number: "1234567890123456")
      expect(card.masked_card_number).to eq("****3456")
    end
  end

  describe "#masked_pin" do
    it "returns asterisks" do
      card = build(:gift_card, pin: "1234")
      expect(card.masked_pin).to eq("****")
    end
  end

  describe "delegation" do
    it "delegates brand_name to brand" do
      brand = create(:brand, name: "Amazon")
      card = build(:gift_card, brand: brand)
      expect(card.brand_name).to eq("Amazon")
    end
  end
end
