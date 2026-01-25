require 'rails_helper'

RSpec.describe "Transactions", type: :request do
  let(:buyer) { create(:user) }
  let(:seller) { create(:user) }
  let(:brand) { create(:brand) }
  let(:gift_card) { create(:gift_card, user: seller, brand: brand, balance: 100) }
  let(:listing) { create(:listing, :for_sale, user: seller, gift_card: gift_card, asking_price: 95) }

  describe "POST /transactions/:id/counter" do
    let(:transaction) { create(:transaction, :sale, buyer: buyer, seller: seller, listing: listing, amount: 85) }

    context "when seller is signed in" do
      before { sign_in seller }

      it "creates a counteroffer" do
        post counter_transaction_path(transaction), params: { counter_amount: 90, counter_message: "How about $90?" }

        expect(response).to redirect_to(transaction_path(transaction))
        expect(transaction.reload.status).to eq("countered")
        expect(transaction.counter_amount).to eq(90)
      end

      it "fails with same amount as original offer" do
        post counter_transaction_path(transaction), params: { counter_amount: 85 }

        expect(response).to redirect_to(transaction_path(transaction))
        expect(flash[:alert]).to be_present
        expect(transaction.reload.status).to eq("pending")
      end
    end

    context "when buyer tries to counter" do
      before { sign_in buyer }

      it "redirects with not authorized" do
        post counter_transaction_path(transaction), params: { counter_amount: 90 }

        expect(response).to redirect_to(transactions_path)
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end

    context "when not signed in" do
      it "redirects to sign in" do
        post counter_transaction_path(transaction), params: { counter_amount: 90 }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /transactions/:id/accept_counter" do
    let(:transaction) { create(:transaction, :sale, :countered, buyer: buyer, seller: seller, listing: listing, amount: 85, counter_amount: 92) }

    context "when buyer is signed in" do
      before { sign_in buyer }

      it "accepts the counteroffer" do
        post accept_counter_transaction_path(transaction)

        expect(response).to redirect_to(transactions_path)
        expect(transaction.reload.status).to eq("accepted")
        expect(transaction.amount).to eq(92)
      end
    end

    context "when seller tries to accept" do
      before { sign_in seller }

      it "redirects with not authorized" do
        post accept_counter_transaction_path(transaction)

        expect(response).to redirect_to(transactions_path)
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end
  end

  describe "POST /transactions/:id/reject_counter" do
    let(:transaction) { create(:transaction, :sale, :countered, buyer: buyer, seller: seller, listing: listing) }

    context "when buyer is signed in" do
      before { sign_in buyer }

      it "rejects the counteroffer" do
        post reject_counter_transaction_path(transaction)

        expect(response).to redirect_to(transactions_path)
        expect(transaction.reload.status).to eq("rejected")
      end
    end

    context "when seller tries to reject" do
      before { sign_in seller }

      it "redirects with not authorized" do
        post reject_counter_transaction_path(transaction)

        expect(response).to redirect_to(transactions_path)
        expect(flash[:alert]).to eq("Not authorized.")
      end
    end
  end

  describe "POST /listings/:listing_id/transactions" do
    before { sign_in buyer }

    it "creates a transaction with custom offer amount" do
      expect {
        post listing_transactions_path(listing), params: {
          transaction: { amount: 80, message: "Would you take $80?" }
        }
      }.to change(Transaction, :count).by(1)

      transaction = Transaction.last
      expect(transaction.amount).to eq(80)
      expect(transaction.message).to eq("Would you take $80?")
      expect(transaction.expires_at).to be_present
    end

    it "defaults to asking price if no amount specified" do
      post listing_transactions_path(listing), params: {
        transaction: { message: "I'll take it!" }
      }

      transaction = Transaction.last
      expect(transaction.amount).to eq(95) # asking price
    end
  end
end
