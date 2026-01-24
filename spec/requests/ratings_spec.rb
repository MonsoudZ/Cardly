require "rails_helper"

RSpec.describe "Ratings", type: :request do
  let(:buyer) { create(:user) }
  let(:seller) { create(:user) }
  let(:gift_card) { create(:gift_card, :listed, user: seller) }
  let(:listing) { create(:listing, :sale, user: seller, gift_card: gift_card) }
  let(:completed_transaction) { create(:transaction, :completed, buyer: buyer, seller: seller, listing: listing) }

  describe "GET /transactions/:transaction_id/rating/new" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get new_transaction_rating_path(completed_transaction)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as buyer" do
      before { sign_in buyer }

      it "returns success" do
        get new_transaction_rating_path(completed_transaction)
        expect(response).to have_http_status(:success)
      end

      it "shows rating form" do
        get new_transaction_rating_path(completed_transaction)
        expect(response.body).to include("Rate Your Transaction")
      end
    end

    context "when transaction is not completed" do
      let(:pending_transaction) { create(:transaction, :pending, buyer: buyer, seller: seller, listing: listing) }

      before { sign_in buyer }

      it "redirects with alert" do
        get new_transaction_rating_path(pending_transaction)
        expect(response).to redirect_to(transaction_path(pending_transaction))
      end
    end

    context "when user already rated" do
      before do
        sign_in buyer
        create(:rating, card_transaction: completed_transaction, rater: buyer, ratee: seller, role: "buyer")
      end

      it "redirects with alert" do
        get new_transaction_rating_path(completed_transaction)
        expect(response).to redirect_to(transaction_path(completed_transaction))
      end
    end

    context "when user is not a participant" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "redirects with alert" do
        get new_transaction_rating_path(completed_transaction)
        expect(response).to redirect_to(transaction_path(completed_transaction))
      end
    end
  end

  describe "POST /transactions/:transaction_id/rating" do
    context "when not authenticated" do
      it "redirects to sign in" do
        post transaction_rating_path(completed_transaction), params: { rating: { score: 5 } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as buyer" do
      before { sign_in buyer }

      it "creates a rating" do
        expect {
          post transaction_rating_path(completed_transaction), params: {
            rating: { score: 5, comment: "Great seller!" }
          }
        }.to change(Rating, :count).by(1)
      end

      it "sets correct rater and ratee" do
        post transaction_rating_path(completed_transaction), params: {
          rating: { score: 5, comment: "Great seller!" }
        }

        rating = Rating.last
        expect(rating.rater).to eq(buyer)
        expect(rating.ratee).to eq(seller)
        expect(rating.role).to eq("buyer")
      end

      it "redirects to transaction with notice" do
        post transaction_rating_path(completed_transaction), params: {
          rating: { score: 5 }
        }
        expect(response).to redirect_to(transaction_path(completed_transaction))
      end

      context "with invalid params" do
        it "renders new with errors" do
          post transaction_rating_path(completed_transaction), params: {
            rating: { score: nil }
          }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when authenticated as seller" do
      before { sign_in seller }

      it "creates a rating for buyer" do
        post transaction_rating_path(completed_transaction), params: {
          rating: { score: 4, comment: "Good buyer!" }
        }

        rating = Rating.last
        expect(rating.rater).to eq(seller)
        expect(rating.ratee).to eq(buyer)
        expect(rating.role).to eq("seller")
      end
    end
  end
end
