class Listing < ApplicationRecord
  LISTING_TYPES = %w[sale trade].freeze
  STATUSES = %w[active sold traded cancelled].freeze

  belongs_to :gift_card
  belongs_to :user, counter_cache: true
  has_many :transactions, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_by, through: :favorites, source: :user

  validates :listing_type, presence: true, inclusion: { in: LISTING_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :asking_price, presence: true, numericality: { greater_than: 0 }, if: :sale?
  validates :trade_preferences, presence: true, if: :trade?
  validate :gift_card_belongs_to_user
  validate :gift_card_has_balance
  validate :asking_price_below_balance, if: :sale?

  before_save :calculate_discount
  before_save :track_price_change
  after_commit :notify_watchers_of_price_drop, if: :price_dropped?

  scope :active, -> { where(status: "active") }
  scope :for_sale, -> { where(listing_type: "sale", status: "active") }
  scope :for_trade, -> { where(listing_type: "trade", status: "active") }
  scope :by_brand, ->(brand_id) { joins(:gift_card).where(gift_cards: { brand_id: brand_id }) }
  scope :search_brand, ->(query) {
    joins(gift_card: :brand).where("brands.name ILIKE ?", "%#{query}%")
  }
  scope :min_discount, ->(percent) { where("discount_percent >= ?", percent) }
  scope :max_price, ->(price) { where("asking_price <= ?", price) }
  scope :min_value, ->(value) { joins(:gift_card).where("gift_cards.balance >= ?", value) }
  scope :max_value, ->(value) { joins(:gift_card).where("gift_cards.balance <= ?", value) }

  delegate :brand, :brand_name, :brand_display_logo, :balance, :masked_card_number, to: :gift_card

  alias_attribute :discount_percentage, :discount_percent

  # Track the old price for price drop notifications
  attr_accessor :old_asking_price

  def sale?
    listing_type == "sale"
  end

  def trade?
    listing_type == "trade"
  end

  def active?
    status == "active"
  end

  def mark_as_sold!
    update!(status: "sold")
    gift_card.update!(status: "active") # New owner will have it active
  end

  def mark_as_traded!
    update!(status: "traded")
  end

  def cancel!
    update!(status: "cancelled")
    gift_card.update!(status: "active")
  end

  def savings
    return 0 unless sale? && asking_price.present?
    gift_card.balance - asking_price
  end

  private

  def calculate_discount
    return unless sale? && asking_price.present? && gift_card.balance.positive?
    self.discount_percent = ((gift_card.balance - asking_price) / gift_card.balance * 100).round(2)
  end

  def track_price_change
    return unless sale? && persisted?
    return unless asking_price_changed?

    self.old_asking_price = asking_price_was
  end

  def price_dropped?
    old_asking_price.present? &&
      asking_price.present? &&
      asking_price < old_asking_price &&
      active?
  end

  def notify_watchers_of_price_drop
    return unless old_asking_price.present?

    favorited_by.find_each do |watcher|
      PriceDropMailer.price_drop_alert(
        watcher,
        self,
        old_asking_price,
        asking_price
      ).deliver_later
    end

    # Clear the tracked price after notifications
    self.old_asking_price = nil
  end

  def gift_card_belongs_to_user
    return if gift_card.nil? || user.nil?
    errors.add(:gift_card, "must belong to you") unless gift_card.user_id == user_id
  end

  def gift_card_has_balance
    return if gift_card.nil?
    errors.add(:gift_card, "must have a balance to list") unless gift_card.balance.positive?
  end

  def asking_price_below_balance
    return unless sale?
    return if asking_price.nil? || gift_card.nil?
    if asking_price > gift_card.balance
      errors.add(:asking_price, "cannot exceed the gift card balance")
    end
  end
end
