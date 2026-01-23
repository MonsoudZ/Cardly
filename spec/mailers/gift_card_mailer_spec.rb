require "rails_helper"

RSpec.describe GiftCardMailer, type: :mailer do
  let(:user) { create(:user, email: "user@example.com") }
  let(:brand) { create(:brand, name: "Amazon") }
  let(:gift_card) do
    create(:gift_card,
      user: user,
      brand: brand,
      balance: 50.00,
      expiration_date: 7.days.from_now
    )
  end

  describe "#expiration_reminder" do
    context "30-day reminder" do
      let(:mail) { described_class.expiration_reminder(gift_card, 30) }

      it "renders the headers" do
        expect(mail.subject).to include("Amazon")
        expect(mail.subject).to include("30 days")
        expect(mail.to).to eq(["user@example.com"])
      end

      it "renders the body" do
        expect(mail.body.encoded).to include("Amazon")
        expect(mail.body.encoded).to include("$50.00")
      end
    end

    context "7-day reminder" do
      let(:mail) { described_class.expiration_reminder(gift_card, 7) }

      it "includes 1 week in subject" do
        expect(mail.subject).to include("1 week")
      end
    end

    context "1-day reminder" do
      let(:mail) { described_class.expiration_reminder(gift_card, 1) }

      it "includes URGENT in subject" do
        expect(mail.subject).to include("URGENT")
        expect(mail.subject).to include("tomorrow")
      end
    end
  end

  describe "#card_expired" do
    let(:expired_card) do
      create(:gift_card,
        user: user,
        brand: brand,
        balance: 25.00,
        expiration_date: 1.day.ago,
        status: "expired"
      )
    end
    let(:mail) { described_class.card_expired(expired_card) }

    it "renders the headers" do
      expect(mail.subject).to include("expired")
      expect(mail.subject).to include("Amazon")
      expect(mail.to).to eq(["user@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("expired")
      expect(mail.body.encoded).to include("$25.00")
    end
  end

  describe "#expiring_cards_digest" do
    let(:cards) do
      [
        create(:gift_card, user: user, brand: brand, balance: 50.00, expiration_date: 5.days.from_now),
        create(:gift_card, user: user, brand: brand, balance: 30.00, expiration_date: 10.days.from_now)
      ]
    end
    let(:mail) { described_class.expiring_cards_digest(user, cards) }

    it "renders the headers" do
      expect(mail.subject).to include("2 gift card")
      expect(mail.subject).to include("expiring soon")
      expect(mail.to).to eq(["user@example.com"])
    end

    it "renders all cards in the body" do
      expect(mail.body.encoded).to include("$50.00")
      expect(mail.body.encoded).to include("$30.00")
      expect(mail.body.encoded).to include("$80.00") # total
    end
  end
end
