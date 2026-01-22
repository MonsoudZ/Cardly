class GiftCard < ApplicationRecord
  STATUSES = %w[active used expired listed].freeze
  ACQUIRED_FROM = %w[purchased gift traded bought_on_cardly other].freeze

  # Encrypt sensitive fields at rest
  encrypts :card_number, deterministic: true
  encrypts :pin

  belongs_to :user
  belongs_to :brand
  has_one :listing, dependent: :destroy
  has_many :card_activities, dependent: :destroy
  has_many :gift_card_tags, dependent: :destroy
  has_many :tags, through: :gift_card_tags

  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :original_value, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :acquired_from, inclusion: { in: ACQUIRED_FROM }, allow_blank: true

  scope :active, -> { where(status: "active") }
  scope :with_balance, -> { where("balance > 0") }
  scope :expiring_soon, -> { where("expiration_date <= ?", 30.days.from_now).where("expiration_date >= ?", Date.current) }
  scope :expired, -> { where("expiration_date < ?", Date.current) }
  scope :by_brand, ->(brand_id) { where(brand_id: brand_id) }
  scope :by_tag, ->(tag_id) { joins(:gift_card_tags).where(gift_card_tags: { tag_id: tag_id }) }
  scope :untagged, -> { left_joins(:gift_card_tags).where(gift_card_tags: { id: nil }) }

  delegate :name, :logo_url, :display_logo, to: :brand, prefix: true

  def expired?
    expiration_date.present? && expiration_date < Date.current
  end

  def expiring_soon?
    expiration_date.present? && expiration_date <= 30.days.from_now && !expired?
  end

  def used?
    balance.zero?
  end

  def balance_percentage
    return 0 if original_value.zero?
    ((balance / original_value) * 100).round
  end

  def listed?
    listing.present? && listing.active?
  end

  def masked_card_number
    return nil if card_number.blank?
    "****#{card_number.last(4)}"
  end

  def masked_pin
    return nil if pin.blank?
    "****"
  end

  def update_status!
    if expired?
      update!(status: "expired")
    elsif used?
      update!(status: "used")
    elsif listed?
      update!(status: "listed")
    else
      update!(status: "active")
    end
  end

  # Spending tracker methods
  def total_spent
    card_activities.purchases.sum(:amount)
  end

  def total_refunded
    card_activities.refunds.sum(:amount)
  end

  def net_spent
    total_spent - total_refunded
  end

  def activity_count
    card_activities.count
  end

  def recent_activities(limit = 5)
    card_activities.reverse_chronological.limit(limit)
  end

  def spending_by_merchant
    card_activities.purchases
                   .where.not(merchant: [nil, ""])
                   .group(:merchant)
                   .sum(:amount)
                   .sort_by { |_, v| -v }
  end
end
