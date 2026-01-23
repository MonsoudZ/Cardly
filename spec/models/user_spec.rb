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
    let(:brand) { create(:brand) }
    let(:gift_card) { create(:gift_card, :listed, user: user, brand: brand) }
    let(:listing) { create(:listing, :sale, user: user, gift_card: gift_card) }

    def create_rating_for_user(score:, role: "buyer")
      transaction = create(:transaction, :completed, buyer: other_user, seller: user, listing: listing)
      create(:rating,
             card_transaction: transaction,
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
        gift_card2 = create(:gift_card, :listed, user: user, brand: brand)
        listing2 = create(:listing, :sale, user: user, gift_card: gift_card2)
        transaction2 = create(:transaction, :completed, buyer: other_user, seller: user, listing: listing2)
        create(:rating, card_transaction: transaction2, rater: other_user, ratee: user, score: 3, role: "buyer")

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
        gift_card2 = create(:gift_card, :listed, user: user, brand: brand)
        listing2 = create(:listing, :sale, user: user, gift_card: gift_card2)
        transaction2 = create(:transaction, :completed, buyer: other_user, seller: user, listing: listing2)
        create(:rating, card_transaction: transaction2, rater: other_user, ratee: user, score: 2, role: "buyer")

        expect(user.positive_rating_percentage).to eq(50)
      end
    end
  end

  describe "profile stats" do
    let(:seller) { create(:user) }
    let(:buyer) { create(:user) }

    describe "#active_listings_count" do
      it "returns count of active listings" do
        brand = create(:brand)
        gift_card1 = create(:gift_card, user: seller, brand: brand, balance: 100)
        gift_card2 = create(:gift_card, user: seller, brand: brand, balance: 50)
        create(:listing, :for_sale, user: seller, gift_card: gift_card1)
        cancelled_listing = create(:listing, :for_sale, user: seller, gift_card: gift_card2)
        cancelled_listing.update!(status: "cancelled")

        expect(seller.active_listings_count).to eq(1)
      end
    end

    describe "#completed_sales_count" do
      it "returns count of completed sales as seller" do
        brand = create(:brand)
        gift_card = create(:gift_card, user: seller, brand: brand, balance: 100)
        listing = create(:listing, :for_sale, user: seller, gift_card: gift_card, asking_price: 85)
        create(:transaction, :completed, listing: listing, seller: seller, buyer: buyer)

        expect(seller.completed_sales_count).to eq(1)
        expect(buyer.completed_sales_count).to eq(0)
      end
    end

    describe "#completed_purchases_count" do
      it "returns count of completed purchases as buyer" do
        brand = create(:brand)
        gift_card = create(:gift_card, user: seller, brand: brand, balance: 100)
        listing = create(:listing, :for_sale, user: seller, gift_card: gift_card, asking_price: 85)
        create(:transaction, :completed, listing: listing, seller: seller, buyer: buyer)

        expect(buyer.completed_purchases_count).to eq(1)
        expect(seller.completed_purchases_count).to eq(0)
      end
    end

    describe "#seller_rating_count" do
      it "returns count of ratings received from sellers" do
        brand = create(:brand)
        gift_card = create(:gift_card, user: seller, brand: brand, balance: 100)
        listing = create(:listing, :for_sale, user: seller, gift_card: gift_card, asking_price: 85)
        transaction = create(:transaction, :completed, listing: listing, seller: seller, buyer: buyer)
        # Seller rates buyer (role: seller), so buyer receives a rating with role: seller
        create(:rating, :from_seller, card_transaction: transaction, rater: seller, ratee: buyer)

        # buyer.seller_rating_count = ratings received where rater role was "seller"
        expect(buyer.seller_rating_count).to eq(1)
      end
    end

    describe "#buyer_rating_count" do
      it "returns count of ratings received from buyers" do
        brand = create(:brand)
        gift_card = create(:gift_card, user: seller, brand: brand, balance: 100)
        listing = create(:listing, :for_sale, user: seller, gift_card: gift_card, asking_price: 85)
        transaction = create(:transaction, :completed, listing: listing, seller: seller, buyer: buyer)
        # Buyer rates seller (role: buyer), so seller receives a rating with role: buyer
        create(:rating, :from_buyer, card_transaction: transaction, rater: buyer, ratee: seller)

        # seller.buyer_rating_count = ratings received where rater role was "buyer"
        expect(seller.buyer_rating_count).to eq(1)
      end
    end

    describe "#total_transactions_count" do
      it "returns sum of completed sales and purchases" do
        brand = create(:brand)

        # User as seller
        gift_card1 = create(:gift_card, user: seller, brand: brand, balance: 100)
        listing1 = create(:listing, :for_sale, user: seller, gift_card: gift_card1, asking_price: 85)
        create(:transaction, :completed, listing: listing1, seller: seller, buyer: buyer)

        # Same user as buyer in another transaction
        other_seller = create(:user)
        gift_card2 = create(:gift_card, user: other_seller, brand: brand, balance: 50)
        listing2 = create(:listing, :for_sale, user: other_seller, gift_card: gift_card2, asking_price: 40)
        create(:transaction, :completed, listing: listing2, seller: other_seller, buyer: seller)

        expect(seller.total_transactions_count).to eq(2)
      end
    end
  end
end
