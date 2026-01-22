class Message < ApplicationRecord
  belongs_to :transaction
  belongs_to :sender, class_name: "User"

  validates :body, presence: true, length: { maximum: 2000 }
  validate :sender_must_be_participant

  scope :unread, -> { where(read_at: nil) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :reverse_chronological, -> { order(created_at: :desc) }

  after_create_commit :notify_recipient

  def read?
    read_at.present?
  end

  def unread?
    read_at.nil?
  end

  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end

  def recipient
    sender == transaction.buyer ? transaction.seller : transaction.buyer
  end

  def from_buyer?
    sender == transaction.buyer
  end

  def from_seller?
    sender == transaction.seller
  end

  private

  def sender_must_be_participant
    return if transaction.nil? || sender.nil?
    unless [ transaction.buyer_id, transaction.seller_id ].include?(sender_id)
      errors.add(:sender, "must be a participant in the transaction")
    end
  end

  def notify_recipient
    MessageMailer.new_message(self).deliver_later
  end
end
