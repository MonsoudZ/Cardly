class Rating < ApplicationRecord
  ROLES = %w[buyer seller].freeze
  SCORE_RANGE = (1..5).freeze

  belongs_to :card_transaction, class_name: "Transaction", foreign_key: "transaction_id"
  belongs_to :rater, class_name: "User"
  belongs_to :ratee, class_name: "User"

  validates :score, presence: true, inclusion: { in: SCORE_RANGE }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :transaction_id, uniqueness: { scope: :rater_id, message: "already rated" }
  validate :transaction_must_be_completed
  validate :rater_must_be_participant
  validate :ratee_must_be_other_participant

  scope :as_buyer, -> { where(role: "buyer") }
  scope :as_seller, -> { where(role: "seller") }
  scope :positive, -> { where("score >= ?", 4) }
  scope :negative, -> { where("score <= ?", 2) }

  def positive?
    score >= 4
  end

  def negative?
    score <= 2
  end

  def neutral?
    score == 3
  end

  private

  def transaction_must_be_completed
    return if card_transaction.nil?
    errors.add(:card_transaction, "must be completed before rating") unless card_transaction.completed?
  end

  def rater_must_be_participant
    return if card_transaction.nil? || rater.nil?
    unless [ card_transaction.buyer_id, card_transaction.seller_id ].include?(rater_id)
      errors.add(:rater, "must be a participant in the transaction")
    end
  end

  def ratee_must_be_other_participant
    return if card_transaction.nil? || ratee.nil? || rater.nil?

    if rater_id == ratee_id
      errors.add(:ratee, "cannot rate yourself")
      return
    end

    unless [ card_transaction.buyer_id, card_transaction.seller_id ].include?(ratee_id)
      errors.add(:ratee, "must be a participant in the transaction")
    end
  end
end
