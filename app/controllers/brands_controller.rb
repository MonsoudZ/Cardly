class BrandsController < ApplicationController
  def index
    @brands = Brand.active.order(:name)
    @brands = @brands.by_category(params[:category]) if params[:category].present?
  end

  def show
    @brand = Brand.find(params[:id])
    @listings = Listing.active
                       .by_brand(@brand.id)
                       .includes(gift_card: :brand, user: [])
                       .order(created_at: :desc)
  end
end
