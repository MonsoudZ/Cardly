class GiftCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_gift_card, only: [ :show, :edit, :update, :destroy, :list_for_sale, :list_for_trade ]
  before_action :authorize_gift_card, only: [ :show, :edit, :update, :destroy, :list_for_sale, :list_for_trade ]

  def index
    redirect_to wallet_path
  end

  def show
  end

  def new
    @gift_card = current_user.gift_cards.build
    @brands = Brand.active.order(:name)
  end

  def create
    @gift_card = current_user.gift_cards.build(gift_card_params)

    if @gift_card.save
      redirect_to wallet_path, notice: "Gift card added to your wallet."
    else
      @brands = Brand.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @brands = Brand.active.order(:name)
  end

  def update
    if @gift_card.update(gift_card_params)
      redirect_to @gift_card, notice: "Gift card updated."
    else
      @brands = Brand.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @gift_card.destroy
    redirect_to wallet_path, notice: "Gift card removed."
  end

  def list_for_sale
    if @gift_card.listed?
      redirect_to @gift_card, alert: "This card is already listed."
      return
    end

    @listing = @gift_card.build_listing(
      user: current_user,
      listing_type: "sale"
    )
  end

  def list_for_trade
    if @gift_card.listed?
      redirect_to @gift_card, alert: "This card is already listed."
      return
    end

    @listing = @gift_card.build_listing(
      user: current_user,
      listing_type: "trade"
    )
  end

  private

  def set_gift_card
    @gift_card = GiftCard.find(params[:id])
  end

  def authorize_gift_card
    redirect_to wallet_path, alert: "Not authorized." unless @gift_card.user == current_user
  end

  def gift_card_params
    params.require(:gift_card).permit(
      :brand_id, :balance, :original_value, :card_number, :pin,
      :expiration_date, :barcode_data, :notes, :acquired_date, :acquired_from,
      tag_ids: []
    )
  end
end
