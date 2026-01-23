require "rails_helper"

RSpec.describe "Favorites", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:gift_card) { create(:gift_card, :listed, user: other_user) }
  let(:listing) { create(:listing, user: other_user, gift_card: gift_card) }

  describe "GET /favorites" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get favorites_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns http success" do
        get favorites_path
        expect(response).to have_http_status(:success)
      end

      it "displays watchlist heading" do
        get favorites_path
        expect(response.body).to include("My Watchlist")
      end

      context "with no favorites" do
        it "shows empty state message" do
          get favorites_path
          expect(response.body).to include("No favorites yet")
        end
      end
    end
  end

  describe "POST /listings/:listing_id/favorite" do
    context "when not authenticated" do
      it "redirects to sign in" do
        post listing_favorite_path(listing)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "creates a favorite" do
        expect {
          post listing_favorite_path(listing)
        }.to change(Favorite, :count).by(1)
      end

      it "redirects back to marketplace" do
        post listing_favorite_path(listing)
        expect(response).to redirect_to(marketplace_path)
      end

      context "with turbo stream format" do
        it "returns turbo stream response" do
          post listing_favorite_path(listing), as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end
    end
  end

  describe "DELETE /listings/:listing_id/favorite" do
    context "when not authenticated" do
      it "redirects to sign in" do
        delete listing_favorite_path(listing)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before do
        sign_in user
        create(:favorite, user: user, listing: listing)
      end

      it "removes the favorite" do
        expect {
          delete listing_favorite_path(listing)
        }.to change(Favorite, :count).by(-1)
      end

      it "redirects back to marketplace" do
        delete listing_favorite_path(listing)
        expect(response).to redirect_to(marketplace_path)
      end

      context "with turbo stream format" do
        it "returns turbo stream response" do
          delete listing_favorite_path(listing), as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end
    end
  end
end
