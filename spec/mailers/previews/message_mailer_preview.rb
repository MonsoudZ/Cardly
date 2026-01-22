# Preview all emails at http://localhost:3000/rails/mailers/message_mailer
class MessageMailerPreview < ActionMailer::Preview
  def new_message
    message = Message.last

    if message
      MessageMailer.new_message(message)
    else
      # Mock message for preview
      buyer = User.first || User.new(email: "buyer@example.com", name: "John Buyer")
      seller = User.second || User.new(email: "seller@example.com", name: "Jane Seller")

      brand = Brand.new(name: "Amazon")
      gift_card = GiftCard.new(brand: brand, balance: 100.00)
      listing = Listing.new(gift_card: gift_card)
      transaction = Transaction.new(
        buyer: buyer,
        seller: seller,
        listing: listing,
        transaction_type: "sale",
        status: "pending"
      )

      mock_message = Message.new(
        transaction: transaction,
        sender: buyer,
        body: "Hi! I'm interested in this gift card. Is it still available? I can pay right away.",
        created_at: Time.current
      )

      # Define recipient method for preview
      mock_message.define_singleton_method(:recipient) { seller }

      MessageMailer.new_message(mock_message)
    end
  end
end
