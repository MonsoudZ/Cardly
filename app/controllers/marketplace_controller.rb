class MarketplaceController < ApplicationController
  def index
    @listings = Listing.active
                       .includes(gift_card: :brand, user: [])
    @listings = apply_filters(@listings)
    @listings = @listings.order(sort_column => sort_direction)
    @brands = Brand.active.order(:name)
  end

  def sales
    @listings = Listing.for_sale
                       .includes(gift_card: :brand, user: [])
    @listings = apply_filters(@listings)
    @listings = @listings.order(sort_column => sort_direction)
    @brands = Brand.active.order(:name)
  end

  def trades
    @listings = Listing.for_trade
                       .includes(gift_card: :brand, user: [])
    @listings = apply_filters(@listings)
    @listings = @listings.order(sort_column => sort_direction)
    @brands = Brand.active.order(:name)
  end

  private

  def apply_filters(listings)
    listings = listings.search_brand(params[:q]) if params[:q].present?
    listings = listings.by_brand(params[:brand_id]) if params[:brand_id].present?
    listings = listings.min_discount(params[:min_discount]) if params[:min_discount].present?
    listings = listings.max_price(params[:max_price]) if params[:max_price].present?
    listings = listings.min_value(params[:min_value]) if params[:min_value].present?
    listings = listings.max_value(params[:max_value]) if params[:max_value].present?
    listings
  end

  def sort_column
    %w[created_at asking_price discount_percent].include?(params[:sort]) ? params[:sort] : "created_at"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
end
