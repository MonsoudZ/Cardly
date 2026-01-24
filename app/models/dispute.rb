class Dispute < ApplicationRecord
  REASONS = %w[
    card_not_working
    wrong_balance
    card_already_used
    card_not_received
    fraudulent_listing
    seller_unresponsive
    other
  ].freeze

  STATUSES = %w[open under_review resolved closed].freeze
  RESOLUTIONS = %w[buyer_favor seller_favor mutual_agreement no_action].freeze

  belongs_to :card_transaction, class_name: "Transaction", foreign_key: "transaction_id"
  belongs_to :initiator, class_name: "User"
  has_many :dispute_messages, dependent: :destroy

  validates :reason, presence: true, inclusion: { in: REASONS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :description, presence: true, length: { minimum: 20, maximum: 2000 }
  validates :resolution, inclusion: { in: RESOLUTIONS }, allow_nil: true
  validate :transaction_must_be_completed_or_accepted
  validate :initiator_must_be_participant
  validate :no_existing_open_dispute

  before_validation :set_default_status, on: :create
  after_create_commit :send_dispute_opened_notification
  after_update_commit :send_status_change_notification, if: :saved_change_to_status?

  scope :open_disputes, -> { where(status: "open") }
  scope :under_review, -> { where(status: "under_review") }
  scope :unresolved, -> { where(status: %w[open under_review]) }
  scope :resolved, -> { where(status: %w[resolved closed]) }
  scope :recent, -> { order(created_at: :desc) }

  def buyer
    card_transaction.buyer
  end

  def seller
    card_transaction.seller
  end

  def other_party
    initiator == buyer ? seller : buyer
  end

  def open?
    status == "open"
  end

  def under_review?
    status == "under_review"
  end

  def resolved?
    status == "resolved"
  end

  def closed?
    status == "closed"
  end

  def can_be_updated_by?(user)
    unresolved? && participant?(user)
  end

  def unresolved?
    %w[open under_review].include?(status)
  end

  def participant?(user)
    [card_transaction.buyer_id, card_transaction.seller_id].include?(user.id)
  end

  def mark_under_review!(admin = nil)
    return false unless open?
    update!(
      status: "under_review",
      reviewed_by_id: admin&.id,
      reviewed_at: Time.current
    )
  end

  def resolve!(resolution_type, resolution_notes, admin = nil)
    return false unless unresolved?
    return false unless RESOLUTIONS.include?(resolution_type)

    ActiveRecord::Base.transaction do
      update!(
        status: "resolved",
        resolution: resolution_type,
        resolution_notes: resolution_notes,
        resolved_by_id: admin&.id,
        resolved_at: Time.current
      )
      apply_resolution(resolution_type)
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Dispute resolution failed: #{e.message}")
    false
  end

  def close!(admin_notes = nil)
    return false unless resolved?
    update!(
      status: "closed",
      admin_notes: admin_notes,
      closed_at: Time.current
    )
  end

  def reopen!
    return false unless closed?
    update!(
      status: "open",
      resolution: nil,
      resolution_notes: nil,
      resolved_at: nil
    )
  end

  def reason_display
    reason.to_s.titleize.gsub("_", " ")
  end

  def resolution_display
    resolution.to_s.titleize.gsub("_", " ")
  end

  def status_badge_class
    case status
    when "open" then "badge-warning"
    when "under_review" then "badge-info"
    when "resolved" then "badge-success"
    when "closed" then "badge-secondary"
    else "badge-secondary"
    end
  end

  private

  def set_default_status
    self.status ||= "open"
  end

  def transaction_must_be_completed_or_accepted
    return if card_transaction.nil?
    unless %w[completed accepted].include?(card_transaction.status)
      errors.add(:card_transaction, "must be completed or accepted to file a dispute")
    end
  end

  def initiator_must_be_participant
    return if initiator.nil? || card_transaction.nil?
    unless participant?(initiator)
      errors.add(:initiator, "must be a participant in the transaction")
    end
  end

  def no_existing_open_dispute
    return unless new_record? && card_transaction.present?
    if Dispute.where(transaction_id: card_transaction.id).unresolved.exists?
      errors.add(:base, "There is already an open dispute for this transaction")
    end
  end

  def apply_resolution(resolution_type)
    case resolution_type
    when "buyer_favor"
      handle_buyer_favor_resolution
    when "seller_favor"
      handle_seller_favor_resolution
    when "mutual_agreement"
      # No automatic action - manual resolution agreed upon
    when "no_action"
      # No action needed
    end
  end

  def handle_buyer_favor_resolution
    # Refund buyer if payment was made
    if card_transaction.sale? && card_transaction.payment_completed?
      card_transaction.update!(payment_status: "refunded")
      # Return gift card to seller
      card_transaction.gift_card.update!(user: seller, status: "active")
    end
  end

  def handle_seller_favor_resolution
    # No refund - transaction stands as completed
  end

  def send_dispute_opened_notification
    DisputeMailer.dispute_opened(self).deliver_later
    DisputeMailer.dispute_opened_to_other_party(self).deliver_later
  end

  def send_status_change_notification
    DisputeMailer.dispute_status_changed(self).deliver_later
  end
end
