class UsersController < ApplicationController
  before_action :set_user

  def show
    @active_listings = @user.active_listings
                            .includes(gift_card: :brand)
                            .order(created_at: :desc)
                            .limit(6)
    @recent_ratings = @user.ratings_received
                           .includes(:rater, :card_transaction)
                           .order(created_at: :desc)
                           .limit(5)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
