class MarketplaceController < ApplicationController
  def index
    @listings = Listing.active
                       .includes(gift_card: :brand, user: [])
                       .order(created_at: :desc)

    @listings = @listings.by_brand(params[:brand_id]) if params[:brand_id].present?
    @brands = Brand.active.order(:name)
  end

  def sales
    @listings = Listing.for_sale
                       .includes(gift_card: :brand, user: [])
                       .order(created_at: :desc)

    @listings = @listings.by_brand(params[:brand_id]) if params[:brand_id].present?
    @brands = Brand.active.order(:name)
  end

  def trades
    @listings = Listing.for_trade
                       .includes(gift_card: :brand, user: [])
                       .order(created_at: :desc)

    @listings = @listings.by_brand(params[:brand_id]) if params[:brand_id].present?
    @brands = Brand.active.order(:name)
  end
end
