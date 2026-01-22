class Transaction < ApplicationRecord
  TYPES = %w[sale trade].freeze
  STATUSES = %w[pending countered accepted rejected completed cancelled expired].freeze

  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"
  belongs_to :listing
  belongs_to :offered_gift_card, class_name: "GiftCard", optional: true

  has_many :ratings, dependent: :destroy
  has_many :messages, dependent: :destroy

  validates :transaction_type, presence: true, inclusion: { in: TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :amount, presence: true, numericality: { greater_than: 0 }, if: :sale?
  validates :counter_amount, numericality: { greater_than: 0 }, allow_nil: true
  validates :offered_gift_card, presence: true, if: :trade?
  validate :buyer_cannot_be_seller
  validate :offered_card_belongs_to_buyer, if: :trade?
  validate :offered_card_has_balance, if: :trade?
  validate :listing_must_be_active, on: :create
  validate :counter_amount_differs_from_original, if: :counter_amount

  after_create_commit :send_new_offer_notification

  scope :pending, -> { where(status: "pending") }
  scope :countered, -> { where(status: "countered") }
  scope :active_offers, -> { where(status: %w[pending countered]) }
  scope :for_seller, ->(user) { where(seller: user) }
  scope :for_buyer, ->(user) { where(buyer: user) }
  scope :not_expired, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

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

  def countered?
    status == "countered"
  end

  def expired?
    status == "expired" || (expires_at.present? && expires_at < Time.current)
  end

  def awaiting_buyer_response?
    countered? && !expired?
  end

  def awaiting_seller_response?
    pending? && !expired?
  end

  def current_offer_amount
    countered? ? counter_amount : amount
  end

  def discount_from_asking
    return nil unless sale? && listing.asking_price.present?
    ((listing.asking_price - current_offer_amount) / listing.asking_price * 100).round(1)
  end

  def buyer_rating
    ratings.find_by(rater: buyer)
  end

  def seller_rating
    ratings.find_by(rater: seller)
  end

  def rated_by?(user)
    ratings.exists?(rater: user)
  end

  def can_be_rated_by?(user)
    completed? && [ buyer_id, seller_id ].include?(user.id) && !rated_by?(user)
  end

  def participant?(user)
    [ buyer_id, seller_id ].include?(user.id)
  end

  def other_party(user)
    user == buyer ? seller : buyer
  end

  def unread_messages_for(user)
    messages.unread.where.not(sender: user)
  end

  def unread_message_count_for(user)
    unread_messages_for(user).count
  end

  def mark_messages_read_for!(user)
    unread_messages_for(user).update_all(read_at: Time.current)
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
    return false unless pending? || countered?
    update!(status: "cancelled")
    send_offer_cancelled_notification
    true
  end

  def counter!(new_amount, message = nil)
    return false unless pending? && sale?
    return false if new_amount == amount

    update!(
      original_amount: original_amount || amount,
      counter_amount: new_amount,
      counter_message: message,
      countered_at: Time.current,
      status: "countered",
      expires_at: 48.hours.from_now
    )
    send_counteroffer_notification
    true
  end

  def accept_counter!
    return false unless countered?

    # Update amount to the counter amount
    update!(amount: counter_amount)

    ActiveRecord::Base.transaction do
      complete_transaction!
    end
    send_counter_accepted_notification
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    Rails.logger.error("Accept counter failed: #{e.message}")
    false
  end

  def reject_counter!
    return false unless countered?
    update!(status: "rejected")
    send_counter_rejected_notification
    true
  end

  def expire!
    return false unless pending? || countered?
    update!(status: "expired")
    send_offer_expired_notification
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

  def counter_amount_differs_from_original
    if counter_amount == amount
      errors.add(:counter_amount, "must be different from the original offer")
    end
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

  def send_counteroffer_notification
    TransactionMailer.counteroffer(self).deliver_later
  end

  def send_counter_accepted_notification
    TransactionMailer.counter_accepted(self).deliver_later
  end

  def send_counter_rejected_notification
    TransactionMailer.counter_rejected(self).deliver_later
  end

  def send_offer_expired_notification
    TransactionMailer.offer_expired(self).deliver_later
  end
end
