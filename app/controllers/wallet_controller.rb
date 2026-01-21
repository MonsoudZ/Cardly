class WalletController < ApplicationController
  before_action :authenticate_user!

  def show
    @gift_cards = current_user.gift_cards.includes(:brand).order(created_at: :desc)
    @total_balance = current_user.wallet_balance
    @expiring_soon = current_user.expiring_soon_cards.includes(:brand)
  end
end
