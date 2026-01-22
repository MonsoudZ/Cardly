class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :gift_cards, dependent: :destroy
  has_many :listings, dependent: :destroy
  has_many :purchases, class_name: "Transaction", foreign_key: :buyer_id, dependent: :destroy
  has_many :sales, class_name: "Transaction", foreign_key: :seller_id, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_listings, through: :favorites, source: :listing

  # Ratings
  has_many :ratings_given, class_name: "Rating", foreign_key: :rater_id, dependent: :destroy
  has_many :ratings_received, class_name: "Rating", foreign_key: :ratee_id, dependent: :destroy

  # Messages
  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :destroy

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

  def pending_offers_received
    sales.pending
  end

  def pending_offers_made
    purchases.pending
  end

  def display_name
    name.presence || email.split("@").first
  end

  def favorited?(listing)
    favorites.exists?(listing_id: listing.id)
  end

  # Rating methods
  def average_rating
    return nil if ratings_received.empty?
    ratings_received.average(:score).to_f.round(1)
  end

  def rating_count
    ratings_received.count
  end

  def positive_rating_percentage
    return nil if ratings_received.empty?
    (ratings_received.positive.count.to_f / ratings_received.count * 100).round
  end

  def seller_rating
    seller_ratings = ratings_received.as_seller
    return nil if seller_ratings.empty?
    seller_ratings.average(:score).to_f.round(1)
  end

  def buyer_rating
    buyer_ratings = ratings_received.as_buyer
    return nil if buyer_ratings.empty?
    buyer_ratings.average(:score).to_f.round(1)
  end

  # Profile stats
  def active_listings_count
    listings.active.count
  end

  def completed_sales_count
    sales.where(status: "completed").count
  end

  def completed_purchases_count
    purchases.where(status: "completed").count
  end

  def seller_rating_count
    ratings_received.as_seller.count
  end

  def buyer_rating_count
    ratings_received.as_buyer.count
  end

  def total_transactions_count
    completed_sales_count + completed_purchases_count
  end
end
