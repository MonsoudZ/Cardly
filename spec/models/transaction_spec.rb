require "rails_helper"

RSpec.describe Transaction, type: :model do
  describe "validations" do
    describe "sale transaction" do
      let(:buyer) { create(:user) }
      let(:seller) { create(:user) }
      let(:gift_card) { create(:gift_card, :listed, user: seller) }
      let(:listing) { create(:listing, :sale, user: seller, gift_card: gift_card) }

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
      let(:seller_gift_card) { create(:gift_card, :listed, user: seller) }
      let(:listing) { create(:listing, :trade, user: seller, gift_card: seller_gift_card) }
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

    it "marks sale transaction as accepted and awaits payment" do
      transaction = create(:transaction, :sale,
                           buyer: buyer,
                           seller: seller,
                           listing: listing)

      expect(transaction.accept!).to be true
      expect(transaction.reload.status).to eq("accepted")
      # Card is not transferred until payment is completed
      expect(gift_card.reload.user).to eq(seller)
    end

    it "completes trade transaction immediately" do
      seller_gift_card = create(:gift_card, :listed, user: seller)
      trade_listing = create(:listing, :trade, gift_card: seller_gift_card, user: seller)
      offered_card = create(:gift_card, user: buyer)
      transaction = create(:transaction, :trade,
                           buyer: buyer,
                           seller: seller,
                           listing: trade_listing,
                           offered_gift_card: offered_card)

      expect(transaction.accept!).to be true
      expect(transaction.reload.status).to eq("completed")
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

  describe "counteroffers" do
    let(:buyer) { create(:user) }
    let(:seller) { create(:user) }
    let(:gift_card) { create(:gift_card, :listed, user: seller) }
    let(:listing) { create(:listing, :sale, user: seller, gift_card: gift_card) }

    describe "#counter!" do
      it "creates a counteroffer" do
        transaction = create(:transaction, :sale, buyer: buyer, seller: seller, listing: listing, amount: 80.00)

        expect(transaction.counter!(90.00, "I can do $90")).to be true
        expect(transaction.status).to eq("countered")
        expect(transaction.counter_amount).to eq(90.00)
        expect(transaction.counter_message).to eq("I can do $90")
        expect(transaction.original_amount).to eq(80.00)
        expect(transaction.expires_at).to be_present
      end

      it "fails if amount is the same as original" do
        transaction = create(:transaction, :sale, buyer: buyer, seller: seller, listing: listing, amount: 80.00)
        expect(transaction.counter!(80.00)).to be false
      end

      it "fails for non-pending transactions" do
        transaction = create(:transaction, :sale, :rejected, buyer: buyer, seller: seller, listing: listing)
        expect(transaction.counter!(90.00)).to be false
      end

      it "fails for trade transactions" do
        seller_gift_card = create(:gift_card, :listed, user: seller)
        trade_listing = create(:listing, :trade, user: seller, gift_card: seller_gift_card)
        offered_card = create(:gift_card, user: buyer)
        transaction = create(:transaction, :trade, buyer: buyer, seller: seller, listing: trade_listing, offered_gift_card: offered_card)
        expect(transaction.counter!(90.00)).to be false
      end
    end

    describe "#accept_counter!" do
      it "accepts the counter and awaits payment" do
        transaction = create(:transaction, :sale, :countered, buyer: buyer, seller: seller, listing: listing, amount: 80.00, counter_amount: 90.00)

        expect(transaction.accept_counter!).to be true
        expect(transaction.status).to eq("accepted")
        expect(transaction.amount).to eq(90.00)
        # Card is not transferred until payment is completed
        expect(gift_card.reload.user).to eq(seller)
      end

      it "fails for non-countered transactions" do
        transaction = create(:transaction, :sale, :pending, buyer: buyer, seller: seller, listing: listing)
        expect(transaction.accept_counter!).to be false
      end
    end

    describe "#reject_counter!" do
      it "rejects the counteroffer" do
        transaction = create(:transaction, :sale, :countered, buyer: buyer, seller: seller, listing: listing)

        expect(transaction.reject_counter!).to be true
        expect(transaction.status).to eq("rejected")
      end

      it "fails for non-countered transactions" do
        transaction = create(:transaction, :sale, :pending, buyer: buyer, seller: seller, listing: listing)
        expect(transaction.reject_counter!).to be false
      end
    end

    describe "#countered?" do
      it "returns true for countered transactions" do
        transaction = build(:transaction, :countered)
        expect(transaction.countered?).to be true
      end
    end

    describe "#expired?" do
      it "returns true when expires_at is in the past" do
        transaction = build(:transaction, expires_at: 1.hour.ago)
        expect(transaction.expired?).to be true
      end

      it "returns false when expires_at is in the future" do
        transaction = build(:transaction, expires_at: 1.hour.from_now)
        expect(transaction.expired?).to be false
      end
    end

    describe "#current_offer_amount" do
      it "returns counter_amount when countered" do
        transaction = build(:transaction, :countered, amount: 80.00, counter_amount: 90.00)
        expect(transaction.current_offer_amount).to eq(90.00)
      end

      it "returns amount when pending" do
        transaction = build(:transaction, :pending, amount: 80.00)
        expect(transaction.current_offer_amount).to eq(80.00)
      end
    end
  end

  describe "email notifications" do
    include ActiveJob::TestHelper

    let(:buyer) { create(:user) }
    let(:seller) { create(:user) }
    let(:gift_card) { create(:gift_card, :listed, user: seller) }
    let(:listing) { create(:listing, :sale, user: seller, gift_card: gift_card) }

    describe "on create" do
      it "sends new offer notification to seller" do
        expect {
          create(:transaction, :sale, buyer: buyer, seller: seller, listing: listing)
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with("TransactionMailer", "new_offer", "deliver_now", anything)
      end
    end

    describe "on accept" do
      it "sends accepted notification to buyer" do
        transaction = create(:transaction, :sale, buyer: buyer, seller: seller, listing: listing)
        clear_enqueued_jobs

        expect {
          transaction.accept!
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with("TransactionMailer", "offer_accepted", "deliver_now", anything)
      end
    end

    describe "on reject" do
      it "sends rejected notification to buyer" do
        transaction = create(:transaction, :sale, buyer: buyer, seller: seller, listing: listing)
        clear_enqueued_jobs

        expect {
          transaction.reject!
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with("TransactionMailer", "offer_rejected", "deliver_now", anything)
      end
    end

    describe "on cancel" do
      it "sends cancelled notification to seller" do
        transaction = create(:transaction, :sale, buyer: buyer, seller: seller, listing: listing)
        clear_enqueued_jobs

        expect {
          transaction.cancel!
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with("TransactionMailer", "offer_cancelled", "deliver_now", anything)
      end
    end

    describe "on counter" do
      it "sends counteroffer notification to buyer" do
        transaction = create(:transaction, :sale, buyer: buyer, seller: seller, listing: listing, amount: 80.00)
        clear_enqueued_jobs

        expect {
          transaction.counter!(90.00, "How about $90?")
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with("TransactionMailer", "counteroffer", "deliver_now", anything)
      end
    end

    describe "on accept_counter" do
      it "sends counter accepted notification to seller" do
        transaction = create(:transaction, :sale, :countered, buyer: buyer, seller: seller, listing: listing)
        clear_enqueued_jobs

        expect {
          transaction.accept_counter!
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with("TransactionMailer", "counter_accepted", "deliver_now", anything)
      end
    end

    describe "on reject_counter" do
      it "sends counter rejected notification to seller" do
        transaction = create(:transaction, :sale, :countered, buyer: buyer, seller: seller, listing: listing)
        clear_enqueued_jobs

        expect {
          transaction.reject_counter!
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with("TransactionMailer", "counter_rejected", "deliver_now", anything)
      end
    end
  end
end
