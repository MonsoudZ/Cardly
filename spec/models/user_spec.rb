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

  describe "ratings" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:listing) { create(:listing, :sale, user: user) }

    def create_rating_for_user(score:, role: "buyer")
      transaction = create(:transaction, :completed, buyer: other_user, seller: user, listing: listing)
      create(:rating,
             transaction: transaction,
             rater: other_user,
             ratee: user,
             score: score,
             role: role)
    end

    describe "#average_rating" do
      it "returns nil when no ratings" do
        expect(user.average_rating).to be_nil
      end

      it "calculates average correctly" do
        create_rating_for_user(score: 5)
        listing2 = create(:listing, :sale, user: user)
        transaction2 = create(:transaction, :completed, buyer: other_user, seller: user, listing: listing2)
        create(:rating, transaction: transaction2, rater: other_user, ratee: user, score: 3, role: "buyer")

        expect(user.average_rating).to eq(4.0)
      end
    end

    describe "#rating_count" do
      it "returns count of ratings received" do
        create_rating_for_user(score: 5)
        expect(user.rating_count).to eq(1)
      end
    end

    describe "#positive_rating_percentage" do
      it "returns nil when no ratings" do
        expect(user.positive_rating_percentage).to be_nil
      end

      it "calculates percentage correctly" do
        create_rating_for_user(score: 5)
        listing2 = create(:listing, :sale, user: user)
        transaction2 = create(:transaction, :completed, buyer: other_user, seller: user, listing: listing2)
        create(:rating, transaction: transaction2, rater: other_user, ratee: user, score: 2, role: "buyer")

        expect(user.positive_rating_percentage).to eq(50)
      end
    end
  end
end
