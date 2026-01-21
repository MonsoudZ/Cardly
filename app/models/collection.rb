class Collection < ApplicationRecord
  belongs_to :user
  has_many :collection_items, dependent: :destroy
  has_many :cards, through: :collection_items

  validates :name, presence: true, uniqueness: { scope: :user_id }

  scope :public_collections, -> { where(public: true) }
  scope :private_collections, -> { where(public: false) }

  def total_value
    collection_items.joins(:card).sum('cards.estimated_value * collection_items.quantity')
  end

  def total_cards
    collection_items.sum(:quantity)
  end

  def items_for_trade
    collection_items.where(for_trade: true)
  end

  def items_for_sale
    collection_items.where(for_sale: true)
  end
end
