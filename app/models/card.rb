class Card < ApplicationRecord
  CARD_TYPES = %w[pokemon mtg sports yugioh other].freeze
  RARITIES = %w[common uncommon rare ultra_rare mythic legendary secret].freeze

  has_many :collection_items, dependent: :destroy
  has_many :collections, through: :collection_items

  validates :name, presence: true
  validates :card_type, presence: true, inclusion: { in: CARD_TYPES }
  validates :rarity, inclusion: { in: RARITIES }, allow_blank: true
  validates :estimated_value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :by_type, ->(type) { where(card_type: type) }
  scope :by_set, ->(set_name) { where(set_name: set_name) }
  scope :by_rarity, ->(rarity) { where(rarity: rarity) }
end
