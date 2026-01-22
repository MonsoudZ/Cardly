class CardActivitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_gift_card
  before_action :set_card_activity, only: [ :show, :edit, :update, :destroy ]

  def index
    @activities = @gift_card.card_activities.reverse_chronological
    @total_spent = @gift_card.total_spent
    @total_refunded = @gift_card.total_refunded
    @spending_by_merchant = @gift_card.spending_by_merchant.first(5)
  end

  def show
  end

  def new
    @card_activity = @gift_card.card_activities.build(
      activity_type: params[:type] || "purchase",
      occurred_at: Time.current
    )
  end

  def create
    @card_activity = @gift_card.card_activities.build(card_activity_params)

    if @card_activity.save
      redirect_to gift_card_path(@gift_card), notice: activity_success_message
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @card_activity.update(card_activity_params)
      redirect_to gift_card_card_activities_path(@gift_card), notice: "Activity updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Restore balance if it was a purchase
    if @card_activity.purchase?
      @gift_card.update_column(:balance, @gift_card.balance + @card_activity.amount)
    elsif @card_activity.refund?
      @gift_card.update_column(:balance, [@gift_card.balance - @card_activity.amount, 0].max)
    end

    @card_activity.destroy
    redirect_to gift_card_card_activities_path(@gift_card), notice: "Activity deleted and balance restored."
  end

  # Quick log purchase from gift card show page
  def quick_purchase
    @card_activity = @gift_card.card_activities.build(
      activity_type: "purchase",
      amount: params[:amount],
      merchant: params[:merchant],
      occurred_at: Time.current
    )

    if @card_activity.save
      respond_to do |format|
        format.html { redirect_to gift_card_path(@gift_card), notice: "Purchase logged! New balance: #{helpers.number_to_currency(@gift_card.balance)}" }
        format.turbo_stream
      end
    else
      redirect_to gift_card_path(@gift_card), alert: "Could not log purchase: #{@card_activity.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_gift_card
    @gift_card = current_user.gift_cards.find(params[:gift_card_id])
  end

  def set_card_activity
    @card_activity = @gift_card.card_activities.find(params[:id])
  end

  def card_activity_params
    params.require(:card_activity).permit(:activity_type, :amount, :merchant, :description, :occurred_at, :balance_after)
  end

  def activity_success_message
    case @card_activity.activity_type
    when "purchase"
      "Purchase logged! New balance: #{helpers.number_to_currency(@gift_card.balance)}"
    when "refund"
      "Refund logged! New balance: #{helpers.number_to_currency(@gift_card.balance)}"
    when "adjustment"
      "Balance adjusted to #{helpers.number_to_currency(@gift_card.balance)}"
    else
      "Activity logged successfully."
    end
  end
end
