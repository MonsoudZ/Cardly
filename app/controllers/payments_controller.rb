class PaymentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [ :checkout, :success, :cancel ]
  before_action :verify_buyer, only: [ :checkout ]
  before_action :verify_payment_eligible, only: [ :checkout ]

  # POST /transactions/:transaction_id/checkout
  def checkout
    # Ensure buyer has a Stripe customer
    ensure_stripe_customer(current_user)

    # Calculate amounts
    payment_amount_cents = (@transaction.current_offer_amount * 100).to_i
    platform_fee_cents = (payment_amount_cents * platform_fee_percentage).to_i
    seller_payout_cents = payment_amount_cents - platform_fee_cents

    # Create Stripe Checkout Session
    session = Stripe::Checkout::Session.create(
      customer: current_user.stripe_customer_id,
      payment_method_types: [ "card" ],
      mode: "payment",
      line_items: [ {
        price_data: {
          currency: "usd",
          unit_amount: payment_amount_cents,
          product_data: {
            name: "#{@transaction.listing.brand_name} Gift Card",
            description: "Gift card purchase from #{@transaction.seller.display_name}"
          }
        },
        quantity: 1
      } ],
      metadata: {
        transaction_id: @transaction.id,
        buyer_id: current_user.id,
        seller_id: @transaction.seller_id
      },
      success_url: success_transaction_payment_url(@transaction) + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cancel_transaction_payment_url(@transaction)
    )

    # Store session and payment info
    @transaction.update!(
      stripe_checkout_session_id: session.id,
      payment_status: "pending",
      payment_amount_cents: payment_amount_cents,
      platform_fee_cents: platform_fee_cents,
      seller_payout_cents: seller_payout_cents
    )

    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    flash[:alert] = "Payment error: #{e.message}"
    redirect_to transaction_path(@transaction)
  end

  # GET /transactions/:transaction_id/payment/success
  def success
    session_id = params[:session_id]

    if session_id.present? && @transaction.stripe_checkout_session_id == session_id
      # Verify payment with Stripe
      session = Stripe::Checkout::Session.retrieve(session_id)

      if session.payment_status == "paid"
        @transaction.complete_payment!(session.payment_intent)
        flash[:notice] = "Payment successful! The gift card has been added to your wallet."
      else
        flash[:alert] = "Payment verification failed. Please contact support."
      end
    else
      flash[:alert] = "Invalid payment session."
    end

    redirect_to transaction_path(@transaction)
  rescue Stripe::StripeError => e
    flash[:alert] = "Error verifying payment: #{e.message}"
    redirect_to transaction_path(@transaction)
  end

  # GET /transactions/:transaction_id/payment/cancel
  def cancel
    @transaction.update!(payment_status: "cancelled") if @transaction.payment_status == "pending"
    flash[:notice] = "Payment was cancelled."
    redirect_to transaction_path(@transaction)
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:transaction_id])
  end

  def verify_buyer
    unless @transaction.buyer_id == current_user.id
      flash[:alert] = "You are not authorized to pay for this transaction."
      redirect_to transactions_path
    end
  end

  def verify_payment_eligible
    unless @transaction.accepted? && @transaction.sale?
      flash[:alert] = "This transaction is not ready for payment."
      redirect_to transaction_path(@transaction)
    end

    if @transaction.payment_status == "completed"
      flash[:notice] = "This transaction has already been paid."
      redirect_to transaction_path(@transaction)
    end
  end

  def ensure_stripe_customer(user)
    return if user.stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: user.email,
      name: user.display_name,
      metadata: { user_id: user.id }
    )

    user.update!(stripe_customer_id: customer.id)
  end

  def platform_fee_percentage
    Rails.application.config.platform_fee_percentage || 0.05
  end
end
