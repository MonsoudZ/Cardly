require 'rails_helper'

RSpec.describe "Admin::Transactions", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:seller) { create(:user, name: "Test Seller") }
  let(:buyer) { create(:user, name: "Test Buyer") }
  let(:brand) { create(:brand, name: "Test Brand") }
  let(:gift_card) { create(:gift_card, user: seller, brand: brand, balance: 100) }
  let(:listing) { create(:listing, :for_sale, user: seller, gift_card: gift_card, asking_price: 85) }
  let!(:transaction) { create(:transaction, listing: listing, seller: seller, buyer: buyer, amount: 85) }

  before { sign_in admin }

  describe "GET /admin/transactions" do
    it "displays all transactions" do
      get admin_transactions_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Test Brand")
      expect(response.body).to include("Test Seller")
      expect(response.body).to include("Test Buyer")
    end

    it "allows filtering by status" do
      completed_transaction = create(:transaction, :completed, listing: listing, seller: seller, buyer: create(:user))

      get admin_transactions_path, params: { status: "completed" }

      expect(response).to have_http_status(:success)
    end

    it "allows filtering by type" do
      get admin_transactions_path, params: { type: "sale" }

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/transactions/:id" do
    it "displays transaction details" do
      get admin_transaction_path(transaction)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Test Brand")
      expect(response.body).to include("$85.00")
    end

    it "displays buyer and seller" do
      get admin_transaction_path(transaction)

      expect(response.body).to include("Test Seller")
      expect(response.body).to include("Test Buyer")
      expect(response.body).to include("BUYER")
      expect(response.body).to include("SELLER")
    end

    it "displays timeline" do
      get admin_transaction_path(transaction)

      expect(response.body).to include("Timeline")
      expect(response.body).to include("Transaction created")
    end

    context "with messages" do
      let!(:message) { create(:message, card_transaction: transaction, sender: buyer, body: "Hello seller!") }

      it "displays messages" do
        get admin_transaction_path(transaction)

        expect(response.body).to include("Messages")
        expect(response.body).to include("Hello seller!")
      end
    end

    context "with ratings" do
      let(:completed_transaction) { create(:transaction, :completed, listing: listing, seller: seller, buyer: buyer) }
      let!(:rating) { create(:rating, :from_buyer, card_transaction: completed_transaction, rater: buyer, ratee: seller, score: 5, comment: "Great!") }

      it "displays ratings" do
        get admin_transaction_path(completed_transaction)

        expect(response.body).to include("Ratings")
        expect(response.body).to include("Great!")
      end
    end
  end

  context "when not an admin" do
    let(:regular_user) { create(:user) }

    before { sign_in regular_user }

    it "denies access to transactions index" do
      get admin_transactions_path
      expect(response).to redirect_to(root_path)
    end
  end
end
