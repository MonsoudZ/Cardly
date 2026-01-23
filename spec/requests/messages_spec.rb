require "rails_helper"

RSpec.describe "Messages", type: :request do
  let(:buyer) { create(:user) }
  let(:seller) { create(:user) }
  let(:gift_card) { create(:gift_card, :listed, user: seller) }
  let(:listing) { create(:listing, :sale, user: seller, gift_card: gift_card) }
  let(:transaction) { create(:transaction, buyer: buyer, seller: seller, listing: listing) }

  describe "POST /transactions/:transaction_id/messages" do
    context "when not authenticated" do
      it "redirects to sign in" do
        post transaction_messages_path(transaction), params: { message: { body: "Hello" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as buyer" do
      before { sign_in buyer }

      it "creates a message" do
        expect {
          post transaction_messages_path(transaction), params: { message: { body: "Hello seller!" } }
        }.to change(Message, :count).by(1)
      end

      it "sets current user as sender" do
        post transaction_messages_path(transaction), params: { message: { body: "Hello!" } }
        expect(Message.last.sender).to eq(buyer)
      end

      it "redirects to transaction with anchor" do
        post transaction_messages_path(transaction), params: { message: { body: "Hello!" } }
        expect(response).to redirect_to(transaction_path(transaction, anchor: "messages"))
      end

      context "with turbo stream format" do
        it "returns turbo stream response" do
          post transaction_messages_path(transaction), params: { message: { body: "Hello!" } }, as: :turbo_stream
          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end
      end

      context "with invalid params" do
        it "redirects with alert" do
          post transaction_messages_path(transaction), params: { message: { body: "" } }
          expect(response).to redirect_to(transaction_path(transaction))
          expect(flash[:alert]).to eq("Could not send message.")
        end
      end
    end

    context "when authenticated as seller" do
      before { sign_in seller }

      it "creates a message" do
        expect {
          post transaction_messages_path(transaction), params: { message: { body: "Hi buyer!" } }
        }.to change(Message, :count).by(1)

        expect(Message.last.sender).to eq(seller)
      end
    end

    context "when not a participant" do
      let(:other_user) { create(:user) }

      before { sign_in other_user }

      it "redirects with alert" do
        post transaction_messages_path(transaction), params: { message: { body: "Hello!" } }
        expect(response).to redirect_to(transactions_path)
        expect(flash[:alert]).to eq("You don't have access to this transaction.")
      end
    end
  end
end
