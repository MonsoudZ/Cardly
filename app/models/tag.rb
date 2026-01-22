class Tag < ApplicationRecord
  # Preset colors for tags
  COLORS = {
    "gray" => "#6B7280",
    "red" => "#EF4444",
    "orange" => "#F97316",
    "amber" => "#F59E0B",
    "yellow" => "#EAB308",
    "lime" => "#84CC16",
    "green" => "#22C55E",
    "emerald" => "#10B981",
    "teal" => "#14B8A6",
    "cyan" => "#06B6D4",
    "sky" => "#0EA5E9",
    "blue" => "#3B82F6",
    "indigo" => "#6366F1",
    "violet" => "#8B5CF6",
    "purple" => "#A855F7",
    "fuchsia" => "#D946EF",
    "pink" => "#EC4899",
    "rose" => "#F43F5E"
  }.freeze

  # Suggested default tags
  SUGGESTED_TAGS = [
    { name: "Groceries", color: "#22C55E" },
    { name: "Restaurants", color: "#F97316" },
    { name: "Entertainment", color: "#8B5CF6" },
    { name: "Shopping", color: "#EC4899" },
    { name: "Gas", color: "#6B7280" },
    { name: "Travel", color: "#0EA5E9" },
    { name: "Coffee", color: "#F59E0B" },
    { name: "Electronics", color: "#3B82F6" }
  ].freeze

  belongs_to :user
  has_many :gift_card_tags, dependent: :destroy
  has_many :gift_cards, through: :gift_card_tags

  validates :name, presence: true, length: { maximum: 30 }
  validates :name, uniqueness: { scope: :user_id, case_sensitive: false }
  validates :color, presence: true

  before_validation :normalize_name
  before_validation :set_default_color

  scope :alphabetical, -> { order(:name) }
  scope :by_usage, -> { left_joins(:gift_card_tags).group(:id).order("COUNT(gift_card_tags.id) DESC") }

  def card_count
    gift_cards.count
  end

  def total_balance
    gift_cards.sum(:balance)
  end

  private

  def normalize_name
    self.name = name.strip.titleize if name.present?
  end

  def set_default_color
    self.color ||= COLORS.values.sample
  end
end
