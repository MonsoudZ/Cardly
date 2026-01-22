require "rails_helper"

RSpec.describe Message, type: :model do
  let(:buyer) { create(:user) }
  let(:seller) { create(:user) }
  let(:listing) { create(:listing, :sale, user: seller) }
  let(:transaction) { create(:transaction, buyer: buyer, seller: seller, listing: listing) }

  describe "validations" do
    subject { build(:message, transaction: transaction, sender: buyer) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires a body" do
      subject.body = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:body]).to include("can't be blank")
    end

    it "limits body to 2000 characters" do
      subject.body = "a" * 2001
      expect(subject).not_to be_valid
    end

    it "requires sender to be a participant" do
      other_user = create(:user)
      subject.sender = other_user
      expect(subject).not_to be_valid
      expect(subject.errors[:sender]).to include("must be a participant in the transaction")
    end
  end

  describe "scopes" do
    let!(:unread_message) { create(:message, :unread, transaction: transaction, sender: buyer) }
    let!(:read_message) { create(:message, :read, transaction: transaction, sender: seller) }

    describe ".unread" do
      it "returns unread messages" do
        expect(Message.unread).to include(unread_message)
        expect(Message.unread).not_to include(read_message)
      end
    end

    describe ".chronological" do
      it "orders by created_at ascending" do
        expect(Message.chronological.first).to eq(unread_message)
      end
    end
  end

  describe "#read? and #unread?" do
    it "returns correct state" do
      unread = build(:message, :unread)
      read = build(:message, :read)

      expect(unread.unread?).to be true
      expect(unread.read?).to be false
      expect(read.read?).to be true
      expect(read.unread?).to be false
    end
  end

  describe "#mark_as_read!" do
    it "sets read_at timestamp" do
      message = create(:message, :unread, transaction: transaction, sender: buyer)
      expect(message.read_at).to be_nil

      message.mark_as_read!
      expect(message.read_at).to be_present
    end

    it "does not update already read messages" do
      original_time = 1.hour.ago
      message = create(:message, transaction: transaction, sender: buyer, read_at: original_time)

      message.mark_as_read!
      expect(message.read_at).to be_within(1.second).of(original_time)
    end
  end

  describe "#recipient" do
    it "returns seller when sender is buyer" do
      message = build(:message, transaction: transaction, sender: buyer)
      expect(message.recipient).to eq(seller)
    end

    it "returns buyer when sender is seller" do
      message = build(:message, transaction: transaction, sender: seller)
      expect(message.recipient).to eq(buyer)
    end
  end

  describe "#from_buyer? and #from_seller?" do
    it "identifies buyer messages" do
      message = build(:message, transaction: transaction, sender: buyer)
      expect(message.from_buyer?).to be true
      expect(message.from_seller?).to be false
    end

    it "identifies seller messages" do
      message = build(:message, transaction: transaction, sender: seller)
      expect(message.from_seller?).to be true
      expect(message.from_buyer?).to be false
    end
  end

  describe "email notification" do
    include ActiveJob::TestHelper

    it "sends notification on create" do
      expect {
        create(:message, transaction: transaction, sender: buyer)
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
        .with("MessageMailer", "new_message", "deliver_now", anything)
    end
  end
end
