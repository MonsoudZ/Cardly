require "rails_helper"

RSpec.describe DisputeMessage, type: :model do
  let(:buyer) { create(:user) }
  let(:seller) { create(:user) }
  let(:gift_card) { create(:gift_card, :listed, user: seller) }
  let(:listing) { create(:listing, :sale, user: seller, gift_card: gift_card) }
  let(:completed_transaction) { create(:transaction, :completed, buyer: buyer, seller: seller, listing: listing) }
  let(:dispute) { create(:dispute, card_transaction: completed_transaction, initiator: buyer) }

  describe "validations" do
    subject { build(:dispute_message, dispute: dispute, sender: buyer) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires content" do
      subject.content = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:content]).to include("can't be blank")
    end

    it "requires content to be at most 2000 characters" do
      subject.content = "a" * 2001
      expect(subject).not_to be_valid
      expect(subject.errors[:content]).to include("is too long (maximum is 2000 characters)")
    end
  end

  describe "associations" do
    it "belongs to a dispute" do
      message = build(:dispute_message)
      expect(message).to respond_to(:dispute)
    end

    it "belongs to a sender" do
      message = build(:dispute_message)
      expect(message).to respond_to(:sender)
    end
  end

  describe "scopes" do
    let!(:message1) { create(:dispute_message, dispute: dispute, sender: buyer, created_at: 1.hour.ago) }
    let!(:message2) { create(:dispute_message, dispute: dispute, sender: seller, created_at: Time.current) }

    describe ".chronological" do
      it "returns messages ordered by created_at ascending" do
        expect(DisputeMessage.chronological).to eq([message1, message2])
      end
    end

    describe ".recent_first" do
      it "returns messages ordered by created_at descending" do
        expect(DisputeMessage.recent_first).to eq([message2, message1])
      end
    end

    describe ".unread" do
      it "returns messages that have not been read" do
        message1.update!(read_at: Time.current)
        expect(DisputeMessage.unread).to eq([message2])
      end
    end
  end

  describe "instance methods" do
    let(:admin) { create(:user, :admin) }
    let(:message) { create(:dispute_message, dispute: dispute, sender: buyer) }

    describe "#from_admin?" do
      it "returns true when sender is admin" do
        admin_message = create(:dispute_message, dispute: dispute, sender: admin)
        expect(admin_message.from_admin?).to be true
      end

      it "returns false when sender is not admin" do
        expect(message.from_admin?).to be false
      end
    end

    describe "#from_initiator?" do
      it "returns true when sender is dispute initiator" do
        expect(message.from_initiator?).to be true
      end

      it "returns false when sender is not initiator" do
        seller_message = create(:dispute_message, dispute: dispute, sender: seller)
        expect(seller_message.from_initiator?).to be false
      end
    end

    describe "#from_other_party?" do
      it "returns true when sender is the other party" do
        seller_message = create(:dispute_message, dispute: dispute, sender: seller)
        expect(seller_message.from_other_party?).to be true
      end

      it "returns false when sender is the initiator" do
        expect(message.from_other_party?).to be false
      end
    end

    describe "#read? and #unread?" do
      it "returns true for read when read_at is present" do
        message.update!(read_at: Time.current)
        expect(message.read?).to be true
        expect(message.unread?).to be false
      end

      it "returns true for unread when read_at is nil" do
        expect(message.read?).to be false
        expect(message.unread?).to be true
      end
    end

    describe "#mark_as_read!" do
      it "sets read_at to current time" do
        message.mark_as_read!
        expect(message.reload.read_at).to be_present
      end

      it "does nothing if already read" do
        original_time = 1.hour.ago
        message.update!(read_at: original_time)
        message.mark_as_read!
        expect(message.reload.read_at).to be_within(1.second).of(original_time)
      end
    end

    describe "#sender_role" do
      it "returns 'Admin' for admin senders" do
        admin_message = create(:dispute_message, dispute: dispute, sender: admin)
        expect(admin_message.sender_role).to eq("Admin")
      end

      it "returns 'Buyer (Initiator)' for buyer who is initiator" do
        expect(message.sender_role).to eq("Buyer (Initiator)")
      end

      it "returns 'Seller' for seller who is not initiator" do
        seller_message = create(:dispute_message, dispute: dispute, sender: seller)
        expect(seller_message.sender_role).to eq("Seller")
      end
    end
  end
end
