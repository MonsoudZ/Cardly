class Transaction < ApplicationRecord
  TYPES = %w[sale trade].freeze
  STATUSES = %w[pending accepted rejected completed cancelled].freeze

  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"
  belongs_to :listing
  belongs_to :offered_gift_card, class_name: "GiftCard", optional: true

  validates :transaction_type, presence: true, inclusion: { in: TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :amount, presence: true, numericality: { greater_than: 0 }, if: :sale?
  validates :offered_gift_card, presence: true, if: :trade?
  validate :buyer_cannot_be_seller
  validate :offered_card_belongs_to_buyer, if: :trade?
  validate :offered_card_has_balance, if: :trade?
  validate :listing_must_be_active, on: :create

  after_create_commit :send_new_offer_notification

  scope :pending, -> { where(status: "pending") }
  scope :for_seller, ->(user) { where(seller: user) }
  scope :for_buyer, ->(user) { where(buyer: user) }

  delegate :gift_card, :brand_name, to: :listing

  def sale?
    transaction_type == "sale"
  end

  def trade?
    transaction_type == "trade"
  end

  def pending?
    status == "pending"
  end

  def accepted?
    status == "accepted"
  end

  def completed?
    status == "completed"
  end

  def accept!
    return false unless pending?

    ActiveRecord::Base.transaction do
      complete_transaction!
    end
    send_offer_accepted_notification
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    Rails.logger.error("Transaction accept failed: #{e.message}")
    false
  end

  def reject!
    return false unless pending?
    update!(status: "rejected")
    send_offer_rejected_notification
    true
  end

  def cancel!
    return false unless pending?
    update!(status: "cancelled")
    send_offer_cancelled_notification
    true
  end

  private

  def complete_transaction!
    if sale?
      complete_sale!
    else
      complete_trade!
    end
    update!(status: "completed")
  end

  def complete_sale!
    # Transfer gift card ownership to buyer
    gift_card = listing.gift_card
    gift_card.update!(user: buyer, status: "active", acquired_from: "bought_on_cardly")
    listing.mark_as_sold!
  end

  def complete_trade!
    # Swap card ownership
    seller_card = listing.gift_card
    buyer_card = offered_gift_card

    # Transfer seller's card to buyer
    seller_card.update!(user: buyer, status: "active", acquired_from: "traded")

    # Transfer buyer's card to seller
    buyer_card.update!(user: seller, status: "active", acquired_from: "traded")

    listing.mark_as_traded!

    # Cancel the offered card's listing if it was listed
    buyer_card.listing&.cancel!
  end

  def buyer_cannot_be_seller
    errors.add(:buyer, "cannot purchase their own listing") if buyer_id == seller_id
  end

  def offered_card_belongs_to_buyer
    return if offered_gift_card.nil? || buyer.nil?
    errors.add(:offered_gift_card, "must belong to you") unless offered_gift_card.user_id == buyer_id
  end

  def offered_card_has_balance
    return if offered_gift_card.nil?
    errors.add(:offered_gift_card, "must have a balance") unless offered_gift_card.balance.positive?
  end

  def listing_must_be_active
    return if listing.nil?
    errors.add(:listing, "is no longer available") unless listing.active?
  end

  # Email notifications
  def send_new_offer_notification
    TransactionMailer.new_offer(self).deliver_later
  end

  def send_offer_accepted_notification
    TransactionMailer.offer_accepted(self).deliver_later
  end

  def send_offer_rejected_notification
    TransactionMailer.offer_rejected(self).deliver_later
  end

  def send_offer_cancelled_notification
    TransactionMailer.offer_cancelled(self).deliver_later
  end
end
