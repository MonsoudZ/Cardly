class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :collections, dependent: :destroy
  has_many :collection_items, through: :collections
  has_many :cards, through: :collection_items

  def total_collection_value
    collection_items.joins(:card).sum('cards.estimated_value * collection_items.quantity')
  end

  def total_cards_count
    collection_items.sum(:quantity)
  end

  def items_for_trade
    collection_items.where(for_trade: true)
  end

  def items_for_sale
    collection_items.where(for_sale: true)
  end

  def display_name
    name.presence || email.split('@').first
  end
end
