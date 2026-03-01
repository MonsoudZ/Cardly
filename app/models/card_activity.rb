class CardActivity < ApplicationRecord
  ACTIVITY_TYPES = %w[purchase refund adjustment balance_check].freeze

  belongs_to :gift_card

  validates :activity_type, presence: true, inclusion: { in: ACTIVITY_TYPES }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :occurred_at, presence: true

  before_validation :set_default_occurred_at
  before_save :calculate_balances
  after_commit :recalculate_gift_card_balance!, on: [ :create, :update, :destroy ], if: :balance_changing_activity?

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

    # Use lock to prevent race conditions
    gift_card.with_lock do
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
  end

  def recalculate_gift_card_balance!
    return unless gift_card

    gift_card.with_lock do
      activities = gift_card.card_activities.order(:occurred_at, :id).to_a

      if activities.empty?
        restored_balance = balance_before || gift_card.balance || 0
        restored_balance = 0 if restored_balance.negative?
        gift_card.update!(balance: restored_balance)
        return
      end

      running_balance = activities.first.balance_before || gift_card.balance || 0

      activities.each do |activity|
        case activity.activity_type
        when "purchase"
          running_balance -= activity.amount
        when "refund"
          running_balance += activity.amount
        when "adjustment"
          running_balance = activity.balance_after || activity.amount || running_balance
        end
      end

      running_balance = 0 if running_balance.negative?
      gift_card.update!(balance: running_balance)
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("Failed to update gift card balance: #{e.message}")
    raise
  end
end
