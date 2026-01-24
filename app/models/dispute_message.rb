class DisputeMessage < ApplicationRecord
  belongs_to :dispute
  belongs_to :sender, class_name: "User"

  validates :content, presence: true, length: { maximum: 2000 }

  scope :chronological, -> { order(created_at: :asc) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  after_create_commit :send_message_notification

  def from_admin?
    sender.admin?
  end

  def from_initiator?
    sender == dispute.initiator
  end

  def from_other_party?
    sender == dispute.other_party
  end

  def read?
    read_at.present?
  end

  def unread?
    read_at.nil?
  end

  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end

  def sender_role
    if from_admin?
      "Admin"
    elsif from_initiator?
      "#{dispute.initiator == dispute.buyer ? 'Buyer' : 'Seller'} (Initiator)"
    else
      dispute.other_party == dispute.buyer ? "Buyer" : "Seller"
    end
  end

  private

  def send_message_notification
    # Notify the other party about the new message
    recipients = [dispute.buyer, dispute.seller].reject { |u| u == sender }
    recipients.each do |recipient|
      DisputeMailer.new_message(self, recipient).deliver_later
    end
  end
end
