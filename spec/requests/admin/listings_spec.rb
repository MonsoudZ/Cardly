require 'rails_helper'

RSpec.describe "Admin::Listings", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let(:brand) { create(:brand, name: "Test Brand") }
  let(:gift_card) { create(:gift_card, user: user, brand: brand, balance: 100) }
  let!(:listing) { create(:listing, :for_sale, user: user, gift_card: gift_card, asking_price: 85) }

  before { sign_in admin }

  describe "GET /admin/listings" do
    it "displays all listings" do
      get admin_listings_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Test Brand")
    end

    it "allows filtering by status" do
      cancelled_listing = create(:listing, :cancelled, user: user, gift_card: create(:gift_card, user: user, brand: brand))

      get admin_listings_path, params: { status: "active" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Test Brand")
    end

    it "allows filtering by type" do
      trade_listing = create(:listing, :for_trade, user: user, gift_card: create(:gift_card, user: user, brand: brand))

      get admin_listings_path, params: { type: "sale" }

      expect(response).to have_http_status(:success)
    end

    it "allows searching by brand name" do
      get admin_listings_path, params: { search: "Test Brand" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Test Brand")
    end
  end

  describe "GET /admin/listings/:id" do
    it "displays listing details" do
      get admin_listing_path(listing)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Test Brand")
      expect(response.body).to include("$100.00")
      expect(response.body).to include("$85.00")
    end

    it "displays seller information" do
      get admin_listing_path(listing)

      expect(response.body).to include(user.display_name)
    end

    it "displays transactions for the listing" do
      get admin_listing_path(listing)

      expect(response.body).to include("Transactions")
    end
  end

  describe "POST /admin/listings/:id/cancel" do
    it "cancels an active listing" do
      post cancel_admin_listing_path(listing)

      expect(response).to redirect_to(admin_listing_path(listing))
      expect(listing.reload.status).to eq("cancelled")
    end
  end

  context "when not an admin" do
    before { sign_in user }

    it "denies access to listings index" do
      get admin_listings_path
      expect(response).to redirect_to(root_path)
    end
  end
end
