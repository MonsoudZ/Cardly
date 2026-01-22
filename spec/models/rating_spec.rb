require "rails_helper"

RSpec.describe Rating, type: :model do
  let(:buyer) { create(:user) }
  let(:seller) { create(:user) }
  let(:listing) { create(:listing, :sale, user: seller) }
  let(:completed_transaction) { create(:transaction, :completed, buyer: buyer, seller: seller, listing: listing) }

  describe "validations" do
    subject do
      build(:rating,
            transaction: completed_transaction,
            rater: buyer,
            ratee: seller,
            role: "buyer")
    end

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires a score" do
      subject.score = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:score]).to include("can't be blank")
    end

    it "requires score between 1 and 5" do
      subject.score = 0
      expect(subject).not_to be_valid

      subject.score = 6
      expect(subject).not_to be_valid

      subject.score = 3
      expect(subject).to be_valid
    end

    it "requires a role" do
      subject.role = nil
      expect(subject).not_to be_valid
    end

    it "requires valid role" do
      subject.role = "invalid"
      expect(subject).not_to be_valid
    end

    it "requires transaction to be completed" do
      pending_transaction = create(:transaction, :pending, buyer: buyer, seller: seller, listing: listing)
      subject.transaction = pending_transaction
      expect(subject).not_to be_valid
      expect(subject.errors[:transaction]).to include("must be completed before rating")
    end

    it "prevents duplicate ratings per transaction" do
      create(:rating, transaction: completed_transaction, rater: buyer, ratee: seller, role: "buyer")
      duplicate = build(:rating, transaction: completed_transaction, rater: buyer, ratee: seller, role: "buyer")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:transaction_id]).to include("already rated")
    end

    it "requires rater to be a participant" do
      other_user = create(:user)
      subject.rater = other_user
      expect(subject).not_to be_valid
      expect(subject.errors[:rater]).to include("must be a participant in the transaction")
    end

    it "requires ratee to be a participant" do
      other_user = create(:user)
      subject.ratee = other_user
      expect(subject).not_to be_valid
      expect(subject.errors[:ratee]).to include("must be a participant in the transaction")
    end

    it "prevents rating yourself" do
      subject.ratee = buyer
      expect(subject).not_to be_valid
      expect(subject.errors[:ratee]).to include("cannot rate yourself")
    end
  end

  describe "scopes" do
    let!(:buyer_rating) { create(:rating, :from_buyer, transaction: completed_transaction) }

    before do
      another_transaction = create(:transaction, :completed, buyer: seller, seller: buyer)
      create(:rating, :from_seller, transaction: another_transaction, rater: buyer, ratee: seller)
    end

    describe ".as_buyer" do
      it "returns ratings from buyers" do
        expect(Rating.as_buyer).to include(buyer_rating)
      end
    end

    describe ".as_seller" do
      it "returns ratings from sellers" do
        expect(Rating.as_seller.count).to eq(1)
      end
    end

    describe ".positive" do
      it "returns ratings with score >= 4" do
        expect(Rating.positive).to include(buyer_rating)
      end
    end
  end

  describe "rating predicates" do
    it "positive? returns true for score >= 4" do
      rating = build(:rating, score: 4)
      expect(rating.positive?).to be true

      rating.score = 5
      expect(rating.positive?).to be true
    end

    it "negative? returns true for score <= 2" do
      rating = build(:rating, score: 2)
      expect(rating.negative?).to be true

      rating.score = 1
      expect(rating.negative?).to be true
    end

    it "neutral? returns true for score == 3" do
      rating = build(:rating, score: 3)
      expect(rating.neutral?).to be true
    end
  end
end
