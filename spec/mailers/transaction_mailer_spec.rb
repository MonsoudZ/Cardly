require "rails_helper"

RSpec.describe TransactionMailer, type: :mailer do
  let(:buyer) { create(:user, email: "buyer@example.com", name: "Buyer Name") }
  let(:seller) { create(:user, email: "seller@example.com", name: "Seller Name") }
  let(:brand) { create(:brand, name: "Amazon") }
  let(:gift_card) { create(:gift_card, :listed, user: seller, brand: brand, balance: 100.00) }
  let(:listing) { create(:listing, :sale, gift_card: gift_card, user: seller, asking_price: 90.00) }

  describe "#new_offer" do
    context "for a sale transaction" do
      let(:transaction) do
        create(:transaction, :sale,
               buyer: buyer,
               seller: seller,
               listing: listing,
               amount: 85.00,
               message: "Great deal!")
      end

      let(:mail) { described_class.new_offer(transaction) }

      it "renders the headers" do
        expect(mail.subject).to include("purchase offer")
        expect(mail.subject).to include("Amazon")
        expect(mail.to).to eq(["seller@example.com"])
        expect(mail.from).to eq(["notifications@cardly.com"])
      end

      it "includes seller name in body" do
        expect(mail.body.encoded).to include("Seller Name")
      end

      it "includes buyer name in body" do
        expect(mail.body.encoded).to include("Buyer Name")
      end

      it "includes offer amount" do
        expect(mail.body.encoded).to include("$85.00")
      end

      it "includes buyer message" do
        expect(mail.body.encoded).to include("Great deal!")
      end
    end

    context "for a trade transaction" do
      let(:buyer_card) { create(:gift_card, user: buyer, brand: create(:brand, name: "Target"), balance: 75.00) }
      let(:trade_listing) { create(:listing, :trade, gift_card: gift_card, user: seller) }
      let(:transaction) do
        create(:transaction, :trade,
               buyer: buyer,
               seller: seller,
               listing: trade_listing,
               offered_gift_card: buyer_card)
      end

      let(:mail) { described_class.new_offer(transaction) }

      it "renders trade-specific subject" do
        expect(mail.subject).to include("trade offer")
      end

      it "includes offered card details" do
        expect(mail.body.encoded).to include("Target")
        expect(mail.body.encoded).to include("$75.00")
      end
    end
  end

  describe "#offer_accepted" do
    let(:transaction) do
      create(:transaction, :sale,
             buyer: buyer,
             seller: seller,
             listing: listing,
             amount: 85.00,
             status: "completed")
    end

    let(:mail) { described_class.offer_accepted(transaction) }

    it "renders the headers" do
      expect(mail.subject).to include("accepted")
      expect(mail.subject).to include("Amazon")
      expect(mail.to).to eq(["buyer@example.com"])
    end

    it "congratulates the buyer" do
      expect(mail.body.encoded).to include("Congratulations")
    end

    it "shows savings for sale" do
      expect(mail.body.encoded).to include("Savings")
    end
  end

  describe "#offer_rejected" do
    let(:transaction) do
      create(:transaction, :sale,
             buyer: buyer,
             seller: seller,
             listing: listing,
             amount: 85.00,
             status: "rejected")
    end

    let(:mail) { described_class.offer_rejected(transaction) }

    it "renders the headers" do
      expect(mail.subject).to include("declined")
      expect(mail.to).to eq(["buyer@example.com"])
    end

    it "apologizes to buyer" do
      expect(mail.body.encoded).to include("Unfortunately")
    end

    it "encourages browsing marketplace" do
      expect(mail.body.encoded).to include("marketplace")
    end
  end

  describe "#offer_cancelled" do
    let(:transaction) do
      create(:transaction, :sale,
             buyer: buyer,
             seller: seller,
             listing: listing,
             amount: 85.00,
             status: "cancelled")
    end

    let(:mail) { described_class.offer_cancelled(transaction) }

    it "renders the headers" do
      expect(mail.subject).to include("cancelled")
      expect(mail.to).to eq(["seller@example.com"])
    end

    it "notifies seller" do
      expect(mail.body.encoded).to include("Seller Name")
    end

    it "mentions listing is still active" do
      expect(mail.body.encoded).to include("still active")
    end
  end
end
