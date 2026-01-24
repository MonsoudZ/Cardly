class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_listing, only: [ :new, :create ]
  before_action :set_transaction, only: [ :show, :accept, :reject, :cancel, :counter, :accept_counter, :reject_counter ]
  before_action :authorize_buyer, only: [ :cancel, :accept_counter, :reject_counter ]
  before_action :authorize_seller, only: [ :accept, :reject, :counter ]

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    @received_offers = current_user.sales.active_offers.includes(listing: { gift_card: :brand }, buyer: [])
    @sent_offers = current_user.purchases.active_offers.includes(listing: { gift_card: :brand }, seller: [])
    @awaiting_response = @sent_offers.countered
    @completed = current_user.purchases.where(status: "completed").or(
      current_user.sales.where(status: "completed")
    ).includes(listing: { gift_card: :brand }).order(updated_at: :desc).limit(10)
  end

  def show
    unless @transaction.buyer == current_user || @transaction.seller == current_user
      redirect_to transactions_path, alert: "Not authorized."
    end
  end

  def new
    if @listing.user == current_user
      redirect_to @listing, alert: "You cannot purchase your own listing."
      return
    end

    @transaction = Transaction.new(
      listing: @listing,
      seller: @listing.user,
      buyer: current_user,
      transaction_type: @listing.listing_type,
      amount: @listing.asking_price
    )

    @available_cards = current_user.gift_cards.active.with_balance.includes(:brand) if @listing.trade?
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.listing = @listing
    @transaction.seller = @listing.user
    @transaction.buyer = current_user
    @transaction.transaction_type = @listing.listing_type

    # Allow custom offer amounts for sales, default to asking price if not specified
    if @listing.sale?
      @transaction.amount = transaction_params[:amount].presence || @listing.asking_price
      @transaction.expires_at = 48.hours.from_now
    end

    if @transaction.save
      redirect_to @transaction, notice: offer_success_message
    else
      @available_cards = current_user.gift_cards.active.with_balance.includes(:brand) if @listing.trade?
      render :new, status: :unprocessable_entity
    end
  end

  def accept
    if @transaction.accept!
      redirect_to transactions_path, notice: "Offer accepted! The transaction has been completed."
    else
      redirect_to @transaction, alert: "Unable to accept offer."
    end
  end

  def reject
    if @transaction.reject!
      redirect_to transactions_path, notice: "Offer rejected."
    else
      redirect_to @transaction, alert: "Unable to reject offer."
    end
  end

  def cancel
    if @transaction.cancel!
      redirect_to transactions_path, notice: "Your offer has been cancelled."
    else
      redirect_to @transaction, alert: "Unable to cancel offer."
    end
  end

  def counter
    if @transaction.counter!(counter_params[:counter_amount], counter_params[:counter_message])
      redirect_to @transaction, notice: "Counteroffer sent! Waiting for buyer's response."
    else
      redirect_to @transaction, alert: "Unable to send counteroffer. Amount must be different from the original offer."
    end
  end

  def accept_counter
    if @transaction.accept_counter!
      redirect_to transactions_path, notice: "Counteroffer accepted! The transaction has been completed."
    else
      redirect_to @transaction, alert: "Unable to accept counteroffer."
    end
  end

  def reject_counter
    if @transaction.reject_counter!
      redirect_to transactions_path, notice: "Counteroffer rejected."
    else
      redirect_to @transaction, alert: "Unable to reject counteroffer."
    end
  end

  private

  def set_listing
    @listing = Listing.active.find(params[:listing_id])
  end

  def set_transaction
    @transaction = Transaction.includes(listing: { gift_card: :brand }, offered_gift_card: :brand)
                              .find(params[:id])
  end

  def authorize_buyer
    redirect_to transactions_path, alert: "Not authorized." unless @transaction.buyer == current_user
  end

  def authorize_seller
    redirect_to transactions_path, alert: "Not authorized." unless @transaction.seller == current_user
  end

  def transaction_params
    params.require(:transaction).permit(:offered_gift_card_id, :message, :amount)
  end

  def counter_params
    params.permit(:counter_amount, :counter_message)
  end

  def offer_success_message
    if @transaction.sale?
      if @transaction.amount < @listing.asking_price
        "Your offer of #{helpers.number_to_currency(@transaction.amount)} has been sent! The seller will review your offer."
      else
        "Purchase offer sent at asking price! The seller will review your offer."
      end
    else
      "Trade offer sent! The seller will review your offer."
    end
  end

  def record_not_found
    redirect_to transactions_path, alert: "Record not found."
  end
end
