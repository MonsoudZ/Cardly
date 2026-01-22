# Preview all emails at http://localhost:3000/rails/mailers/price_drop_mailer
class PriceDropMailerPreview < ActionMailer::Preview
  def price_drop_alert
    user = User.first || User.new(email: "watcher@example.com", name: "John Watcher")
    listing = Listing.for_sale.first

    if listing
      old_price = listing.asking_price + 15.00
      PriceDropMailer.price_drop_alert(user, listing, old_price, listing.asking_price)
    else
      # Fallback mock when no data exists
      brand = Brand.new(name: "Amazon")
      gift_card = GiftCard.new(brand: brand, balance: 100.00)
      mock_listing = Listing.new(
        gift_card: gift_card,
        asking_price: 75.00,
        discount_percent: 25.0,
        status: "active"
      )

      PriceDropMailer.price_drop_alert(user, mock_listing, 90.00, 75.00)
    end
  end
end
