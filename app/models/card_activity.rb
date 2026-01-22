class CardActivity < ApplicationRecord
  ACTIVITY_TYPES = %w[purchase refund adjustment balance_check].freeze

  belongs_to :gift_card

  validates :activity_type, presence: true, inclusion: { in: ACTIVITY_TYPES }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :occurred_at, presence: true

  before_validation :set_default_occurred_at
  before_save :calculate_balances
  after_save :update_gift_card_balance, if: :balance_changing_activity?

  scope :chronological, -> { order(occurred_at: :asc) }
  scope :reverse_chronological, -> { order(occurred_at: :desc) }
  scope :purchases, -> { where(activity_type: "purchase") }
  scope :refunds, -> { where(activity_type: "refund") }
  scope :recent, -> { where("occurred_at >= ?", 30.days.ago) }

  def purchase?
    activity_type == "purchase"
  end

  def refund?
    activity_type == "refund"
  end

  def adjustment?
    activity_type == "adjustment"
  end

  def balance_check?
    activity_type == "balance_check"
  end

  def balance_changing_activity?
    purchase? || refund? || adjustment?
  end

  def signed_amount
    case activity_type
    when "purchase"
      -amount
    when "refund"
      amount
    when "adjustment"
      balance_after - balance_before if balance_before && balance_after
    else
      0
    end
  end

  private

  def set_default_occurred_at
    self.occurred_at ||= Time.current
  end

  def calculate_balances
    return unless gift_card

    self.balance_before = gift_card.balance

    case activity_type
    when "purchase"
      self.balance_after = [balance_before - amount, 0].max
    when "refund"
      self.balance_after = balance_before + amount
    when "adjustment"
      # For adjustments, balance_after should be set explicitly or equal to amount
      self.balance_after ||= amount
    when "balance_check"
      self.balance_after = balance_before
    end
  end

  def update_gift_card_balance
    return unless balance_after && gift_card

    gift_card.update_column(:balance, balance_after)
  end
end
