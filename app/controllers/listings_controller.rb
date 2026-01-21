class ListingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_listing, only: [ :show, :edit, :update, :destroy, :cancel ]
  before_action :authorize_listing, only: [ :edit, :update, :destroy, :cancel ]

  def show
  end

  def create
    @gift_card = current_user.gift_cards.find(params[:gift_card_id])
    @listing = @gift_card.build_listing(listing_params.merge(user: current_user))

    if @listing.save
      @gift_card.update!(status: "listed")
      redirect_to marketplace_path, notice: "Your card has been listed!"
    else
      render "gift_cards/list_for_#{@listing.listing_type}", status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @listing.update(listing_params)
      redirect_to @listing, notice: "Listing updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @listing.gift_card.update!(status: "active")
    @listing.destroy
    redirect_to wallet_path, notice: "Listing removed."
  end

  def cancel
    @listing.cancel!
    redirect_to wallet_path, notice: "Listing cancelled."
  end

  private

  def set_listing
    @listing = Listing.find(params[:id])
  end

  def authorize_listing
    redirect_to marketplace_path, alert: "Not authorized." unless @listing.user == current_user
  end

  def listing_params
    params.require(:listing).permit(:listing_type, :asking_price, :trade_preferences)
  end
end
