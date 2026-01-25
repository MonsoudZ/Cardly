module Admin
  class ListingsController < BaseController
    before_action :set_listing, only: [ :show, :cancel ]

    def index
      @listings = Listing.includes(:user, gift_card: :brand).order(created_at: :desc)

      # Filter by status
      if params[:status].present?
        @listings = @listings.where(status: params[:status])
      end

      # Filter by type
      if params[:type].present?
        @listings = @listings.where(listing_type: params[:type])
      end

      # Search by brand
      if params[:search].present?
        @listings = @listings.joins(gift_card: :brand)
                              .where("brands.name ILIKE ?", "%#{params[:search]}%")
      end

      @listings = @listings.limit(50)
    end

    def show
      @transactions = @listing.transactions.includes(:buyer, :seller).order(created_at: :desc)
    end

    def cancel
      @listing.cancel!
      redirect_to admin_listing_path(@listing), notice: "Listing cancelled."
    end

    private

    def set_listing
      @listing = Listing.find(params[:id])
    end
  end
end
