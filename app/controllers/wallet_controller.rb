class WalletController < ApplicationController
  before_action :authenticate_user!

  def show
    @gift_cards = current_user.gift_cards.includes(:brand, :tags).order(created_at: :desc)

    # Filter by tag
    if params[:tag].present?
      @selected_tag = current_user.tags.find_by(id: params[:tag])
      @gift_cards = @gift_cards.by_tag(params[:tag]) if @selected_tag
    elsif params[:untagged].present?
      @gift_cards = @gift_cards.untagged
    end

    # Filter by status
    case params[:status]
    when "active"
      @gift_cards = @gift_cards.active.with_balance
    when "used"
      @gift_cards = @gift_cards.where(status: "used")
    when "expired"
      @gift_cards = @gift_cards.where(status: "expired")
    when "listed"
      @gift_cards = @gift_cards.where(status: "listed")
    end

    @tags = current_user.tags.alphabetical.includes(:gift_cards)
    @total_balance = current_user.wallet_balance
    @expiring_soon = current_user.expiring_soon_cards.includes(:brand)
  end
end
