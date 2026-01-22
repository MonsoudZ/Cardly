require "rails_helper"

RSpec.describe Transaction, type: :model do
  describe "validations" do
    describe "sale transaction" do
      let(:buyer) { create(:user) }
      let(:seller) { create(:user) }
      let(:listing) { create(:listing, :sale, user: seller) }

      subject do
        build(:transaction, :sale, buyer: buyer, seller: seller, listing: listing)
      end

      it "is valid with valid attributes" do
        expect(subject).to be_valid
      end

      it "requires amount for sales" do
        subject.amount = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:amount]).to include("can't be blank")
      end

      it "prevents buyer from being seller" do
        subject.buyer = seller
        expect(subject).not_to be_valid
        expect(subject.errors[:buyer]).to include("cannot purchase their own listing")
      end
    end

    describe "trade transaction" do
      let(:buyer) { create(:user) }
      let(:seller) { create(:user) }
      let(:listing) { create(:listing, :trade, user: seller) }
      let(:offered_card) { create(:gift_card, user: buyer) }

      subject do
        build(:transaction, :trade,
              buyer: buyer,
              seller: seller,
              listing: listing,
              offered_gift_card: offered_card)
      end

      it "is valid with valid attributes" do
        expect(subject).to be_valid
      end

      it "requires offered gift card" do
        subject.offered_gift_card = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:offered_gift_card]).to include("can't be blank")
      end

      it "requires offered card to belong to buyer" do
        subject.offered_gift_card = create(:gift_card, user: seller)
        expect(subject).not_to be_valid
        expect(subject.errors[:offered_gift_card]).to include("must belong to you")
      end
    end
  end

  describe "type predicates" do
    describe "#sale?" do
      it "returns true for sale transactions" do
        transaction = build(:transaction, :sale)
        expect(transaction.sale?).to be true
        expect(transaction.trade?).to be false
      end
    end

    describe "#trade?" do
      it "returns true for trade transactions" do
        transaction = build(:transaction, :trade)
        expect(transaction.trade?).to be true
        expect(transaction.sale?).to be false
      end
    end
  end

  describe "#pending?" do
    it "returns true for pending transactions" do
      transaction = build(:transaction, :pending)
      expect(transaction.pending?).to be true
    end
  end

  describe "#accept!" do
    let(:buyer) { create(:user) }
    let(:seller) { create(:user) }
    let(:gift_card) { create(:gift_card, :listed, user: seller) }
    let(:listing) { create(:listing, :sale, gift_card: gift_card, user: seller) }

    it "completes a sale transaction and transfers ownership" do
      transaction = create(:transaction, :sale,
                           buyer: buyer,
                           seller: seller,
                           listing: listing)

      expect(transaction.accept!).to be true
      expect(transaction.reload.status).to eq("completed")
      expect(gift_card.reload.user).to eq(buyer)
    end
  end

  describe "#reject!" do
    it "changes status to rejected" do
      transaction = create(:transaction, :pending)
      expect(transaction.reject!).to be true
      expect(transaction.status).to eq("rejected")
    end
  end

  describe "#cancel!" do
    it "changes status to cancelled" do
      transaction = create(:transaction, :pending)
      expect(transaction.cancel!).to be true
      expect(transaction.status).to eq("cancelled")
    end
  end

  describe "state transitions" do
    it "cannot accept non-pending transaction" do
      transaction = create(:transaction, status: "rejected")
      expect(transaction.accept!).to be false
    end
  end
end
