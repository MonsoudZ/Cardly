class FavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_listing, only: [ :create, :destroy ]

  def index
    @favorites = current_user.favorites
                             .active_listings
                             .includes(listing: { gift_card: :brand, user: [] })
                             .order(created_at: :desc)
  end

  def create
    @favorite = current_user.favorites.build(listing: @listing)

    respond_to do |format|
      if @favorite.save
        format.html { redirect_back fallback_location: marketplace_path, notice: "Added to watchlist." }
        format.turbo_stream
      else
        format.html { redirect_back fallback_location: marketplace_path, alert: "Could not add to watchlist." }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  def destroy
    @favorite = current_user.favorites.find_by(listing: @listing)

    respond_to do |format|
      if @favorite&.destroy
        format.html { redirect_back fallback_location: marketplace_path, notice: "Removed from watchlist." }
        format.turbo_stream
      else
        format.html { redirect_back fallback_location: marketplace_path, alert: "Could not remove from watchlist." }
        format.turbo_stream { head :unprocessable_entity }
      end
    end
  end

  private

  def set_listing
    @listing = Listing.find(params[:listing_id])
  end
end
