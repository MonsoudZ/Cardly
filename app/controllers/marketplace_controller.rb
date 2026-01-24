class MarketplaceController < ApplicationController
  def index
    @listings = Listing.active
                       .includes(gift_card: :brand, user: [])
    @listings = apply_filters(@listings)
    @listings = @listings.order(sort_column => sort_direction)
                         .page(params[:page]).per(24)
    @brands = Brand.active.order(:name)
  end

  def sales
    @listings = Listing.for_sale
                       .includes(gift_card: :brand, user: [])
    @listings = apply_filters(@listings)
    @listings = @listings.order(sort_column => sort_direction)
                         .page(params[:page]).per(24)
    @brands = Brand.active.order(:name)
  end

  def trades
    @listings = Listing.for_trade
                       .includes(gift_card: :brand, user: [])
    @listings = apply_filters(@listings)
    @listings = @listings.order(sort_column => sort_direction)
                         .page(params[:page]).per(24)
    @brands = Brand.active.order(:name)
  end

  private

  def apply_filters(listings)
    listings = listings.search_brand(params[:q]) if params[:q].present?
    
    # Validate and filter by brand_id
    if params[:brand_id].present?
      brand_id = params[:brand_id].to_i
      listings = listings.by_brand(brand_id) if brand_id > 0 && Brand.exists?(brand_id)
    end
    
    # Validate and filter by min_discount (0-100)
    if params[:min_discount].present?
      min_discount = params[:min_discount].to_f
      listings = listings.min_discount(min_discount) if min_discount >= 0 && min_discount <= 100
    end
    
    # Validate and filter by max_price (must be positive)
    if params[:max_price].present?
      max_price = params[:max_price].to_f
      listings = listings.max_price(max_price) if max_price > 0
    end
    
    # Validate and filter by min_value (must be positive)
    if params[:min_value].present?
      min_value = params[:min_value].to_f
      listings = listings.min_value(min_value) if min_value > 0
    end
    
    # Validate and filter by max_value (must be positive)
    if params[:max_value].present?
      max_value = params[:max_value].to_f
      listings = listings.max_value(max_value) if max_value > 0
    end
    
    listings
  end

  def sort_column
    %w[created_at asking_price discount_percent].include?(params[:sort]) ? params[:sort] : "created_at"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end
end
