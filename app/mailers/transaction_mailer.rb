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

  # Notify buyer when seller sends a counteroffer
  def counteroffer(transaction)
    @transaction = transaction
    @buyer = transaction.buyer
    @seller = transaction.seller
    @listing = transaction.listing

    mail(
      to: @buyer.email,
      subject: "Counteroffer received for #{@listing.brand_name} gift card"
    )
  end

  # Notify seller when buyer accepts their counteroffer
  def counter_accepted(transaction)
    @transaction = transaction
    @seller = transaction.seller
    @buyer = transaction.buyer
    @listing = transaction.listing

    mail(
      to: @seller.email,
      subject: "Your counteroffer for #{@listing.brand_name} gift card was accepted!"
    )
  end

  # Notify seller when buyer rejects their counteroffer
  def counter_rejected(transaction)
    @transaction = transaction
    @seller = transaction.seller
    @buyer = transaction.buyer
    @listing = transaction.listing

    mail(
      to: @seller.email,
      subject: "Your counteroffer for #{@listing.brand_name} gift card was declined"
    )
  end

  # Notify both parties when an offer expires
  def offer_expired(transaction)
    @transaction = transaction
    @buyer = transaction.buyer
    @seller = transaction.seller
    @listing = transaction.listing

    mail(
      to: @buyer.email,
      subject: "Your offer for #{@listing.brand_name} gift card has expired"
    )
  end
end
