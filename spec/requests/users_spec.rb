require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /u/:id" do
    let(:user) { create(:user, name: "Test Seller") }

    it "displays the user's public profile" do
      get user_path(user)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Test Seller")
      expect(response.body).to include("Member since")
    end

    it "displays the user's display name when name is not set" do
      user_without_name = create(:user, :without_name)
      get user_path(user_without_name)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(user_without_name.display_name)
    end

    context "with active listings" do
      let!(:brand) { create(:brand) }
      let!(:gift_card) { create(:gift_card, user: user, brand: brand, balance: 100) }
      let!(:listing) { create(:listing, :for_sale, user: user, gift_card: gift_card, asking_price: 85) }

      it "displays active listings" do
        get user_path(user)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Active Listings")
        expect(response.body).to include(brand.name)
      end
    end

    context "with ratings" do
      let(:buyer) { create(:user) }
      let!(:brand) { create(:brand) }
      let!(:gift_card) { create(:gift_card, user: user, brand: brand, balance: 100) }
      let!(:listing) { create(:listing, :for_sale, user: user, gift_card: gift_card, asking_price: 85) }
      let!(:transaction) { create(:transaction, :completed, listing: listing, seller: user, buyer: buyer) }
      let!(:rating) { create(:rating, :from_buyer, transaction: transaction, rater: buyer, ratee: user, score: 5, comment: "Great seller!") }

      it "displays ratings received" do
        get user_path(user)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Recent Reviews")
        expect(response.body).to include("Great seller!")
      end

      it "displays average rating" do
        get user_path(user)

        expect(response.body).to include("5.0")
      end
    end

    context "with transaction history" do
      let(:buyer) { create(:user) }
      let!(:brand) { create(:brand) }
      let!(:gift_card) { create(:gift_card, user: user, brand: brand, balance: 100) }
      let!(:listing) { create(:listing, :for_sale, user: user, gift_card: gift_card, asking_price: 85) }
      let!(:transaction) { create(:transaction, :completed, listing: listing, seller: user, buyer: buyer) }

      it "displays transaction stats" do
        get user_path(user)

        expect(response.body).to include("Completed Sales")
        expect(response.body).to include("1")
      end
    end

    it "returns 404 for non-existent user" do
      expect {
        get user_path(id: 999999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
