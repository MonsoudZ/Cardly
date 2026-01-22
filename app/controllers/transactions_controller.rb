class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [ :show, :accept, :reject, :cancel ]
  before_action :authorize_buyer, only: [ :cancel ]
  before_action :authorize_seller, only: [ :accept, :reject ]

  def index
    @received_offers = current_user.pending_offers_received.includes(listing: { gift_card: :brand }, buyer: [])
    @sent_offers = current_user.pending_offers_made.includes(listing: { gift_card: :brand }, seller: [])
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
    @listing = Listing.active.find(params[:listing_id])

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
    @listing = Listing.find(params[:listing_id])
    @transaction = Transaction.new(transaction_params)
    @transaction.listing = @listing
    @transaction.seller = @listing.user
    @transaction.buyer = current_user
    @transaction.transaction_type = @listing.listing_type
    @transaction.amount = @listing.asking_price if @listing.sale?

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

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def authorize_buyer
    redirect_to transactions_path, alert: "Not authorized." unless @transaction.buyer == current_user
  end

  def authorize_seller
    redirect_to transactions_path, alert: "Not authorized." unless @transaction.seller == current_user
  end

  def transaction_params
    params.require(:transaction).permit(:offered_gift_card_id, :message)
  end

  def offer_success_message
    if @transaction.sale?
      "Purchase offer sent! The seller will review your offer."
    else
      "Trade offer sent! The seller will review your offer."
    end
  end
end
