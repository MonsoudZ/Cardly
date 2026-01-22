require "rails_helper"

RSpec.describe Listing, type: :model do
  describe "validations" do
    describe "sale listing" do
      subject { build(:listing, :sale) }

      it "is valid with valid attributes" do
        expect(subject).to be_valid
      end

      it "requires listing_type" do
        subject.listing_type = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:listing_type]).to include("can't be blank")
      end

      it "requires valid listing_type" do
        subject.listing_type = "invalid"
        expect(subject).not_to be_valid
      end

      it "requires asking_price" do
        subject.asking_price = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:asking_price]).to include("can't be blank")
      end

      it "requires asking_price to be positive" do
        subject.asking_price = 0
        expect(subject).not_to be_valid
        expect(subject.errors[:asking_price]).to include("must be greater than 0")
      end
    end

    describe "trade listing" do
      subject { build(:listing, :trade) }

      it "is valid with valid attributes" do
        expect(subject).to be_valid
      end

      it "requires trade_preferences" do
        subject.trade_preferences = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:trade_preferences]).to include("can't be blank")
      end
    end
  end

  describe "type predicates" do
    describe "#sale?" do
      it "returns true for sale listings" do
        listing = build(:listing, :sale)
        expect(listing.sale?).to be true
        expect(listing.trade?).to be false
      end
    end

    describe "#trade?" do
      it "returns true for trade listings" do
        listing = build(:listing, :trade)
        expect(listing.trade?).to be true
        expect(listing.sale?).to be false
      end
    end
  end

  describe "#active?" do
    it "returns true for active listings" do
      listing = build(:listing, status: "active")
      expect(listing.active?).to be true
    end

    it "returns false for cancelled listings" do
      listing = build(:listing, :cancelled)
      expect(listing.active?).to be false
    end
  end

  describe "scopes" do
    let!(:sale_listing) { create(:listing, :sale) }
    let!(:trade_listing) { create(:listing, :trade) }
    let!(:cancelled_listing) { create(:listing, :cancelled) }

    describe ".active" do
      it "returns only active listings" do
        expect(Listing.active).to include(sale_listing, trade_listing)
        expect(Listing.active).not_to include(cancelled_listing)
      end
    end

    describe ".for_sale" do
      it "returns sale listings" do
        expect(Listing.for_sale).to include(sale_listing)
        expect(Listing.for_sale).not_to include(trade_listing)
      end
    end

    describe ".for_trade" do
      it "returns trade listings" do
        expect(Listing.for_trade).to include(trade_listing)
        expect(Listing.for_trade).not_to include(sale_listing)
      end
    end
  end

  describe "#savings" do
    it "calculates correctly for sale listings" do
      gift_card = create(:gift_card, balance: 100.00)
      listing = build(:listing, gift_card: gift_card, asking_price: 90.00)
      expect(listing.savings).to eq(10.00)
    end
  end

  describe "delegation" do
    it "delegates brand_name to gift_card" do
      brand = create(:brand, name: "Starbucks")
      gift_card = create(:gift_card, :listed, brand: brand)
      listing = build(:listing, gift_card: gift_card)
      expect(listing.brand_name).to eq("Starbucks")
    end
  end

  describe "#cancel!" do
    it "updates status to cancelled" do
      listing = create(:listing)
      listing.cancel!
      expect(listing.status).to eq("cancelled")
    end
  end
end
