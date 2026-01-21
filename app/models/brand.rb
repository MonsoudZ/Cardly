class Brand < ApplicationRecord
  CATEGORIES = %w[retail food entertainment travel gas grocery other].freeze

  has_many :gift_cards, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }

  def display_logo
    logo_url.presence || "https://placehold.co/100x60?text=#{name.first(3).upcase}"
  end
end
