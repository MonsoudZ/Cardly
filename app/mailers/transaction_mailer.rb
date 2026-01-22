class TransactionMailer < ApplicationMailer
  # Notify seller when they receive a new offer
  def new_offer(transaction)
    @transaction = transaction
    @seller = transaction.seller
    @buyer = transaction.buyer
    @listing = transaction.listing

    mail(
      to: @seller.email,
      subject: "New #{transaction.sale? ? 'purchase' : 'trade'} offer for your #{@listing.brand_name} gift card"
    )
  end

  # Notify buyer when their offer is accepted
  def offer_accepted(transaction)
    @transaction = transaction
    @buyer = transaction.buyer
    @listing = transaction.listing

    mail(
      to: @buyer.email,
      subject: "Your offer for the #{@listing.brand_name} gift card was accepted!"
    )
  end

  # Notify buyer when their offer is rejected
  def offer_rejected(transaction)
    @transaction = transaction
    @buyer = transaction.buyer
    @listing = transaction.listing

    mail(
      to: @buyer.email,
      subject: "Your offer for the #{@listing.brand_name} gift card was declined"
    )
  end

  # Notify seller when buyer cancels their offer
  def offer_cancelled(transaction)
    @transaction = transaction
    @seller = transaction.seller
    @buyer = transaction.buyer
    @listing = transaction.listing

    mail(
      to: @seller.email,
      subject: "Offer cancelled for your #{@listing.brand_name} gift card"
    )
  end
end
