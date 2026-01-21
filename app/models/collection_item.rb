class CollectionItem < ApplicationRecord
  CONDITIONS = %w[mint near_mint excellent good poor].freeze

  belongs_to :collection
  belongs_to :card

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :condition, inclusion: { in: CONDITIONS }, allow_blank: true
  validates :acquired_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :asking_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :card_id, uniqueness: { scope: :collection_id, message: "already exists in this collection" }

  scope :for_trade, -> { where(for_trade: true) }
  scope :for_sale, -> { where(for_sale: true) }
  scope :by_condition, ->(condition) { where(condition: condition) }

  delegate :name, :card_type, :set_name, :rarity, :estimated_value, :image_url, to: :card, prefix: true

  def total_value
    (card.estimated_value || 0) * quantity
  end

  def display_condition
    condition&.titleize || 'Unknown'
  end
end
