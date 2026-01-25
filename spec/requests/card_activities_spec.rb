require 'rails_helper'

RSpec.describe "CardActivities", type: :request do
  let(:user) { create(:user) }
  let(:brand) { create(:brand) }
  let(:gift_card) { create(:gift_card, user: user, brand: brand, balance: 100, original_value: 100) }

  before { sign_in user }

  describe "GET /gift_cards/:gift_card_id/card_activities" do
    it "displays the spending history" do
      create(:card_activity, :purchase, gift_card: gift_card, amount: 25, merchant: "Test Store")

      get gift_card_card_activities_path(gift_card)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Spending History")
      expect(response.body).to include("Test Store")
    end

    it "displays spending stats" do
      create(:card_activity, :purchase, gift_card: gift_card, amount: 25)
      create(:card_activity, :refund, gift_card: gift_card, amount: 5)

      get gift_card_card_activities_path(gift_card)

      expect(response.body).to include("Total Spent")
      expect(response.body).to include("Total Refunded")
    end
  end

  describe "GET /gift_cards/:gift_card_id/card_activities/new" do
    it "displays the new activity form" do
      get new_gift_card_card_activity_path(gift_card)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Log")
    end

    it "accepts activity type parameter" do
      get new_gift_card_card_activity_path(gift_card, type: "refund")

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Log Refund")
    end
  end

  describe "POST /gift_cards/:gift_card_id/card_activities" do
    it "creates a new purchase activity" do
      expect {
        post gift_card_card_activities_path(gift_card), params: {
          card_activity: {
            activity_type: "purchase",
            amount: 25.00,
            merchant: "Coffee Shop",
            occurred_at: Time.current
          }
        }
      }.to change(CardActivity, :count).by(1)

      expect(response).to redirect_to(gift_card_path(gift_card))
      expect(gift_card.reload.balance).to eq(75)
    end

    it "creates a refund activity" do
      gift_card.update!(balance: 50)

      post gift_card_card_activities_path(gift_card), params: {
        card_activity: {
          activity_type: "refund",
          amount: 10.00,
          merchant: "Returns Dept",
          occurred_at: Time.current
        }
      }

      expect(gift_card.reload.balance).to eq(60)
    end

    it "handles invalid activity" do
      post gift_card_card_activities_path(gift_card), params: {
        card_activity: {
          activity_type: "purchase",
          amount: nil
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /gift_cards/:gift_card_id/card_activities/:id" do
    let!(:activity) { create(:card_activity, :purchase, gift_card: gift_card, amount: 25, merchant: "Old Store") }

    it "updates the activity" do
      patch gift_card_card_activity_path(gift_card, activity), params: {
        card_activity: { merchant: "New Store" }
      }

      expect(response).to redirect_to(gift_card_card_activities_path(gift_card))
      expect(activity.reload.merchant).to eq("New Store")
    end
  end

  describe "DELETE /gift_cards/:gift_card_id/card_activities/:id" do
    let!(:activity) { create(:card_activity, :purchase, gift_card: gift_card, amount: 25) }

    it "deletes the activity and restores balance" do
      # After creating the purchase activity, balance should be 75
      gift_card.reload
      expect(gift_card.balance).to eq(75)

      expect {
        delete gift_card_card_activity_path(gift_card, activity)
      }.to change(CardActivity, :count).by(-1)

      expect(response).to redirect_to(gift_card_card_activities_path(gift_card))
      expect(gift_card.reload.balance).to eq(100)
    end
  end

  describe "POST /gift_cards/:gift_card_id/card_activities/quick_purchase" do
    it "logs a quick purchase" do
      expect {
        post quick_purchase_gift_card_card_activities_path(gift_card), params: {
          amount: 15.00,
          merchant: "Quick Stop"
        }
      }.to change(CardActivity, :count).by(1)

      expect(response).to redirect_to(gift_card_path(gift_card))
      expect(gift_card.reload.balance).to eq(85)
    end
  end

  context "when accessing another user's gift card" do
    let(:other_user) { create(:user) }
    let(:other_gift_card) { create(:gift_card, user: other_user, brand: brand) }

    it "denies access" do
      get gift_card_card_activities_path(other_gift_card)
      expect(response).to have_http_status(:not_found)
    end
  end
end
