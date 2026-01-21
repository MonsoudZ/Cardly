class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :gift_cards, dependent: :destroy
  has_many :listings, dependent: :destroy

  def wallet_balance
    gift_cards.active.with_balance.sum(:balance)
  end

  def total_cards_count
    gift_cards.count
  end

  def active_cards
    gift_cards.active.with_balance
  end

  def expiring_soon_cards
    gift_cards.expiring_soon
  end

  def listed_cards
    gift_cards.where(status: "listed")
  end

  def active_listings
    listings.active
  end

  def display_name
    name.presence || email.split("@").first
  end
end
