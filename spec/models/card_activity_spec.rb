require 'rails_helper'

RSpec.describe CardActivity, type: :model do
  let(:user) { create(:user) }
  let(:brand) { create(:brand) }
  let(:gift_card) { create(:gift_card, user: user, brand: brand, balance: 100, original_value: 100) }

  describe "validations" do
    it "is valid with valid attributes" do
      activity = build(:card_activity, gift_card: gift_card)
      expect(activity).to be_valid
    end

    it "requires an activity_type" do
      activity = build(:card_activity, gift_card: gift_card, activity_type: nil)
      expect(activity).not_to be_valid
      expect(activity.errors[:activity_type]).to include("can't be blank")
    end

    it "requires a valid activity_type" do
      activity = build(:card_activity, gift_card: gift_card, activity_type: "invalid")
      expect(activity).not_to be_valid
    end

    it "requires an amount" do
      activity = build(:card_activity, gift_card: gift_card, amount: nil)
      expect(activity).not_to be_valid
    end

    it "requires amount to be greater than 0" do
      activity = build(:card_activity, gift_card: gift_card, amount: 0)
      expect(activity).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:purchase) { create(:card_activity, :purchase, gift_card: gift_card, occurred_at: 1.day.ago) }
    let!(:refund) { create(:card_activity, :refund, gift_card: gift_card, amount: 5, occurred_at: Time.current) }

    it "filters purchases" do
      expect(CardActivity.purchases).to include(purchase)
      expect(CardActivity.purchases).not_to include(refund)
    end

    it "filters refunds" do
      expect(CardActivity.refunds).to include(refund)
      expect(CardActivity.refunds).not_to include(purchase)
    end

    it "orders chronologically" do
      expect(CardActivity.chronological.first).to eq(purchase)
      expect(CardActivity.chronological.last).to eq(refund)
    end

    it "orders reverse chronologically" do
      expect(CardActivity.reverse_chronological.first).to eq(refund)
      expect(CardActivity.reverse_chronological.last).to eq(purchase)
    end
  end

  describe "balance calculations" do
    context "for purchases" do
      it "decreases the balance" do
        activity = create(:card_activity, :purchase, gift_card: gift_card, amount: 25)

        expect(activity.balance_before).to eq(100)
        expect(activity.balance_after).to eq(75)
        expect(gift_card.reload.balance).to eq(75)
      end

      it "does not go below zero" do
        activity = create(:card_activity, :purchase, gift_card: gift_card, amount: 150)

        expect(activity.balance_after).to eq(0)
        expect(gift_card.reload.balance).to eq(0)
      end
    end

    context "for refunds" do
      before { gift_card.update!(balance: 50) }

      it "increases the balance" do
        activity = create(:card_activity, :refund, gift_card: gift_card, amount: 25)

        expect(activity.balance_before).to eq(50)
        expect(activity.balance_after).to eq(75)
        expect(gift_card.reload.balance).to eq(75)
      end
    end
  end

  describe "activity type methods" do
    it "identifies purchase activities" do
      activity = build(:card_activity, :purchase)
      expect(activity.purchase?).to be true
      expect(activity.refund?).to be false
    end

    it "identifies refund activities" do
      activity = build(:card_activity, :refund)
      expect(activity.refund?).to be true
      expect(activity.purchase?).to be false
    end

    it "identifies adjustment activities" do
      activity = build(:card_activity, :adjustment)
      expect(activity.adjustment?).to be true
    end

    it "identifies balance_check activities" do
      activity = build(:card_activity, :balance_check)
      expect(activity.balance_check?).to be true
    end
  end

  describe "#signed_amount" do
    it "returns negative for purchases" do
      activity = build(:card_activity, :purchase, amount: 25)
      expect(activity.signed_amount).to eq(-25)
    end

    it "returns positive for refunds" do
      activity = build(:card_activity, :refund, amount: 25)
      expect(activity.signed_amount).to eq(25)
    end
  end
end
