class StripeWebhookEvent < ApplicationRecord
  validates :stripe_event_id, presence: true, uniqueness: true
  validates :event_type, presence: true

  scope :processed, -> { where(processed: true) }
  scope :unprocessed, -> { where(processed: false) }
  scope :by_type, ->(type) { where(event_type: type) }

  def mark_as_processed!
    update!(processed: true)
  end

  def mark_as_failed!(error_message)
    update!(processed: true, error_message: error_message)
  end
end
