# Preview all emails at http://localhost:3000/rails/mailers/transaction_mailer
class TransactionMailerPreview < ActionMailer::Preview
  def new_offer
    transaction = Transaction.pending.first || mock_sale_transaction
    TransactionMailer.new_offer(transaction)
  end

  def offer_accepted
    transaction = Transaction.where(status: "completed").first || mock_sale_transaction("completed")
    TransactionMailer.offer_accepted(transaction)
  end

  def offer_rejected
    transaction = Transaction.where(status: "rejected").first || mock_sale_transaction("rejected")
    TransactionMailer.offer_rejected(transaction)
  end

  def offer_cancelled
    transaction = Transaction.where(status: "cancelled").first || mock_sale_transaction("cancelled")
    TransactionMailer.offer_cancelled(transaction)
  end

  private

  def mock_sale_transaction(status = "pending")
    # Use first available data or create mock objects for preview
    buyer = User.first || User.new(email: "buyer@example.com", name: "John Buyer")
    seller = User.second || User.new(email: "seller@example.com", name: "Jane Seller")
    listing = Listing.first

    if listing
      Transaction.new(
        buyer: buyer,
        seller: listing.user,
        listing: listing,
        transaction_type: "sale",
        status: status,
        amount: listing.asking_price || 50.00,
        message: "I'd love to buy this gift card!"
      )
    else
      # Fallback mock when no data exists
      brand = Brand.new(name: "Amazon")
      gift_card = GiftCard.new(brand: brand, balance: 100.00)
      mock_listing = Listing.new(gift_card: gift_card, asking_price: 85.00)

      Transaction.new(
        buyer: buyer,
        seller: seller,
        listing: mock_listing,
        transaction_type: "sale",
        status: status,
        amount: 85.00,
        message: "I'd love to buy this gift card!"
      )
    end
  end
end
