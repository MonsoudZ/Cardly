require 'rails_helper'

RSpec.describe ExpirationReminderJob, type: :job do
  let(:user) { create(:user) }
  let(:brand) { create(:brand) }

  describe "#perform" do
    context "30-day reminders" do
      it "sends reminders for cards expiring in 30 days" do
        card = create(:gift_card,
          user: user,
          brand: brand,
          balance: 50.00,
          expiration_date: 25.days.from_now,
          reminder_sent_at: nil
        )

        expect {
          described_class.perform_now
        }.to have_enqueued_mail(GiftCardMailer, :expiration_reminder).with(card, 30)

        expect(card.reload.reminder_sent_at).to be_present
      end

      it "does not send reminders for already reminded cards" do
        card = create(:gift_card,
          user: user,
          brand: brand,
          balance: 50.00,
          expiration_date: 25.days.from_now,
          reminder_sent_at: 1.day.ago
        )

        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(GiftCardMailer, :expiration_reminder)
      end

      it "does not send reminders for zero balance cards" do
        card = create(:gift_card,
          user: user,
          brand: brand,
          balance: 0,
          expiration_date: 25.days.from_now,
          reminder_sent_at: nil
        )

        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(GiftCardMailer, :expiration_reminder)
      end
    end

    context "7-day reminders" do
      it "sends reminders for cards expiring in 7 days" do
        card = create(:gift_card,
          user: user,
          brand: brand,
          balance: 50.00,
          expiration_date: 5.days.from_now,
          reminder_7_day_sent_at: nil
        )

        expect {
          described_class.perform_now
        }.to have_enqueued_mail(GiftCardMailer, :expiration_reminder).with(card, 7)

        expect(card.reload.reminder_7_day_sent_at).to be_present
      end
    end

    context "1-day reminders" do
      it "sends reminders for cards expiring tomorrow" do
        card = create(:gift_card,
          user: user,
          brand: brand,
          balance: 50.00,
          expiration_date: 1.day.from_now,
          reminder_1_day_sent_at: nil
        )

        expect {
          described_class.perform_now
        }.to have_enqueued_mail(GiftCardMailer, :expiration_reminder).with(card, 1)

        expect(card.reload.reminder_1_day_sent_at).to be_present
      end
    end

    context "expired cards" do
      it "marks expired cards and sends notification" do
        card = create(:gift_card,
          user: user,
          brand: brand,
          balance: 50.00,
          expiration_date: 1.day.ago,
          status: "active"
        )

        expect {
          described_class.perform_now
        }.to have_enqueued_mail(GiftCardMailer, :card_expired).with(card)

        expect(card.reload.status).to eq("expired")
      end

      it "does not re-notify already expired cards" do
        card = create(:gift_card,
          user: user,
          brand: brand,
          balance: 50.00,
          expiration_date: 1.day.ago,
          status: "expired"
        )

        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(GiftCardMailer, :card_expired)
      end
    end
  end
end
