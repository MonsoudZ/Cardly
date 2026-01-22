class RatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction
  before_action :ensure_can_rate, only: [ :new, :create ]

  def new
    @rating = @transaction.ratings.build(
      rater: current_user,
      ratee: other_party,
      role: current_user_role
    )
  end

  def create
    @rating = @transaction.ratings.build(rating_params)
    @rating.rater = current_user
    @rating.ratee = other_party
    @rating.role = current_user_role

    if @rating.save
      redirect_to transaction_path(@transaction), notice: "Thank you for your rating!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:transaction_id])
  end

  def ensure_can_rate
    unless @transaction.can_be_rated_by?(current_user)
      redirect_to transaction_path(@transaction), alert: "You cannot rate this transaction."
    end
  end

  def other_party
    current_user == @transaction.buyer ? @transaction.seller : @transaction.buyer
  end

  def current_user_role
    current_user == @transaction.buyer ? "buyer" : "seller"
  end

  def rating_params
    params.require(:rating).permit(:score, :comment)
  end
end
