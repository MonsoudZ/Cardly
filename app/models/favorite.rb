class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :listing, counter_cache: true

  validates :listing_id, uniqueness: { scope: :user_id, message: "already in your watchlist" }

  scope :active_listings, -> { joins(:listing).where(listings: { status: "active" }) }
end
