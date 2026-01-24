require "rails_helper"

RSpec.describe Dispute, type: :model do
  let(:buyer) { create(:user) }
  let(:seller) { create(:user) }
  let(:gift_card) { create(:gift_card, :listed, user: seller) }
  let(:listing) { create(:listing, :sale, user: seller, gift_card: gift_card) }
  let(:completed_transaction) { create(:transaction, :completed, buyer: buyer, seller: seller, listing: listing) }

  describe "validations" do
    subject { build(:dispute, card_transaction: completed_transaction, initiator: buyer) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires a reason" do
      subject.reason = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:reason]).to include("can't be blank")
    end

    it "requires reason to be in the allowed list" do
      subject.reason = "invalid_reason"
      expect(subject).not_to be_valid
      expect(subject.errors[:reason]).to include("is not included in the list")
    end

    it "requires a description" do
      subject.description = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:description]).to include("can't be blank")
    end

    it "requires description to be at least 20 characters" do
      subject.description = "Too short"
      expect(subject).not_to be_valid
      expect(subject.errors[:description]).to include("is too short (minimum is 20 characters)")
    end

    it "requires description to be at most 2000 characters" do
      subject.description = "a" * 2001
      expect(subject).not_to be_valid
      expect(subject.errors[:description]).to include("is too long (maximum is 2000 characters)")
    end

    it "requires transaction to be completed or accepted" do
      pending_transaction = create(:transaction, :pending, buyer: buyer, seller: seller, listing: listing)
      subject.card_transaction = pending_transaction
      expect(subject).not_to be_valid
      expect(subject.errors[:card_transaction]).to include("must be completed or accepted to file a dispute")
    end

    it "requires initiator to be a participant" do
      other_user = create(:user)
      subject.initiator = other_user
      expect(subject).not_to be_valid
      expect(subject.errors[:initiator]).to include("must be a participant in the transaction")
    end

    it "prevents creating a second dispute for same transaction" do
      create(:dispute, card_transaction: completed_transaction, initiator: buyer)
      second_dispute = build(:dispute, card_transaction: completed_transaction, initiator: seller)
      expect(second_dispute).not_to be_valid
      expect(second_dispute.errors[:base]).to include("There is already an open dispute for this transaction")
    end
  end

  describe "associations" do
    it "belongs to a transaction" do
      dispute = build(:dispute)
      expect(dispute).to respond_to(:card_transaction)
    end

    it "belongs to an initiator" do
      dispute = build(:dispute)
      expect(dispute).to respond_to(:initiator)
    end

    it "has many dispute messages" do
      dispute = create(:dispute, card_transaction: completed_transaction, initiator: buyer)
      expect(dispute).to respond_to(:dispute_messages)
    end
  end

  describe "scopes" do
    let!(:open_dispute) { create(:dispute, card_transaction: completed_transaction, initiator: buyer, status: "open") }

    before do
      another_transaction = create(:transaction, :completed, buyer: seller, seller: buyer)
      create(:dispute, card_transaction: another_transaction, initiator: buyer, status: "resolved")
    end

    describe ".open_disputes" do
      it "returns disputes with open status" do
        expect(Dispute.open_disputes).to include(open_dispute)
      end
    end

    describe ".unresolved" do
      it "returns disputes that are not resolved" do
        expect(Dispute.unresolved).to include(open_dispute)
      end
    end

    describe ".resolved" do
      it "returns resolved disputes" do
        expect(Dispute.resolved.count).to eq(1)
      end
    end
  end

  describe "status methods" do
    let(:dispute) { create(:dispute, card_transaction: completed_transaction, initiator: buyer) }

    describe "#mark_under_review!" do
      it "changes status to under_review" do
        expect(dispute.mark_under_review!).to be true
        expect(dispute.reload.status).to eq("under_review")
      end

      it "sets reviewed_at timestamp" do
        dispute.mark_under_review!
        expect(dispute.reload.reviewed_at).to be_present
      end

      it "fails if dispute is not open" do
        dispute.update!(status: "resolved")
        expect(dispute.mark_under_review!).to be false
      end
    end

    describe "#resolve!" do
      before { dispute.update!(status: "under_review") }

      it "changes status to resolved with valid resolution" do
        expect(dispute.resolve!("buyer_favor", "Test resolution")).to be true
        expect(dispute.reload.status).to eq("resolved")
        expect(dispute.resolution).to eq("buyer_favor")
      end

      it "sets resolved_at timestamp" do
        dispute.resolve!("seller_favor", "Test resolution")
        expect(dispute.reload.resolved_at).to be_present
      end

      it "fails with invalid resolution" do
        expect(dispute.resolve!("invalid", "Test")).to be false
      end
    end

    describe "#close!" do
      before do
        dispute.update!(status: "resolved", resolution: "buyer_favor")
      end

      it "changes status to closed" do
        expect(dispute.close!).to be true
        expect(dispute.reload.status).to eq("closed")
      end

      it "sets closed_at timestamp" do
        dispute.close!
        expect(dispute.reload.closed_at).to be_present
      end

      it "fails if dispute is not resolved" do
        dispute.update!(status: "open", resolution: nil)
        expect(dispute.close!).to be false
      end
    end

    describe "#reopen!" do
      before do
        dispute.update!(status: "closed", resolution: "buyer_favor")
      end

      it "changes status to open" do
        expect(dispute.reopen!).to be true
        expect(dispute.reload.status).to eq("open")
      end

      it "clears resolution" do
        dispute.reopen!
        expect(dispute.reload.resolution).to be_nil
      end

      it "fails if dispute is not closed" do
        dispute.update!(status: "open", resolution: nil)
        expect(dispute.reopen!).to be false
      end
    end
  end

  describe "helper methods" do
    let(:dispute) { create(:dispute, card_transaction: completed_transaction, initiator: buyer) }

    describe "#buyer" do
      it "returns the transaction buyer" do
        expect(dispute.buyer).to eq(buyer)
      end
    end

    describe "#seller" do
      it "returns the transaction seller" do
        expect(dispute.seller).to eq(seller)
      end
    end

    describe "#other_party" do
      it "returns the other party (seller when initiator is buyer)" do
        expect(dispute.other_party).to eq(seller)
      end

      it "returns the buyer when initiator is seller" do
        dispute.update!(initiator: seller)
        expect(dispute.other_party).to eq(buyer)
      end
    end

    describe "#participant?" do
      it "returns true for buyer" do
        expect(dispute.participant?(buyer)).to be true
      end

      it "returns true for seller" do
        expect(dispute.participant?(seller)).to be true
      end

      it "returns false for non-participant" do
        other_user = create(:user)
        expect(dispute.participant?(other_user)).to be false
      end
    end

    describe "#reason_display" do
      it "returns human-readable reason" do
        dispute.update!(reason: "card_not_working")
        expect(dispute.reason_display).to eq("Card Not Working")
      end
    end
  end
end
