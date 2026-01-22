require "rails_helper"

RSpec.describe PriceDropMailer, type: :mailer do
  let(:user) { create(:user, email: "watcher@example.com", name: "Watcher") }
  let(:seller) { create(:user) }
  let(:brand) { create(:brand, name: "Amazon") }
  let(:gift_card) { create(:gift_card, :listed, user: seller, brand: brand, balance: 100.00) }
  let(:listing) { create(:listing, :sale, gift_card: gift_card, user: seller, asking_price: 90.00) }

  describe "#price_drop_alert" do
    let(:old_price) { 90.00 }
    let(:new_price) { 80.00 }
    let(:mail) { described_class.price_drop_alert(user, listing, old_price, new_price) }

    it "renders the headers" do
      expect(mail.subject).to include("Price drop alert")
      expect(mail.subject).to include("Amazon")
      expect(mail.subject).to include("$80.00")
      expect(mail.to).to eq(["watcher@example.com"])
      expect(mail.from).to eq(["notifications@cardly.com"])
    end

    it "includes user name in body" do
      expect(mail.body.encoded).to include("Watcher")
    end

    it "includes old price" do
      expect(mail.body.encoded).to include("$90.00")
    end

    it "includes new price" do
      expect(mail.body.encoded).to include("$80.00")
    end

    it "includes savings amount" do
      expect(mail.body.encoded).to include("$10.00")
    end

    it "includes savings percentage" do
      # (90-80)/90 * 100 = 11%
      expect(mail.body.encoded).to include("11%")
    end

    it "includes card value" do
      expect(mail.body.encoded).to include("$100.00")
    end

    it "includes link to manage watchlist" do
      expect(mail.body.encoded).to include("watchlist")
    end
  end
end
