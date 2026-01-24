class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :stripe ]
  skip_before_action :authenticate_user!, only: [ :stripe ], raise: false

  # POST /webhooks/stripe
  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    webhook_secret = Rails.application.config.stripe_webhook_secret

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
    rescue JSON::ParserError
      render json: { error: "Invalid payload" }, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError
      render json: { error: "Invalid signature" }, status: :bad_request
      return
    end

    # Check if event was already processed (idempotency)
    webhook_event = StripeWebhookEvent.find_or_create_by(stripe_event_id: event.id) do |we|
      we.event_type = event.type
      we.payload = event.to_json
    end

    # Return early if already processed
    if webhook_event.processed?
      Rails.logger.info "Stripe webhook event #{event.id} already processed (idempotency)"
      render json: { received: true, message: "Event already processed" }, status: :ok
      return
    end

    # Process the event
    begin
      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "payment_intent.succeeded"
        handle_payment_succeeded(event.data.object)
      when "payment_intent.payment_failed"
        handle_payment_failed(event.data.object)
      when "account.updated"
        handle_connect_account_updated(event.data.object)
      when "transfer.created"
        handle_transfer_created(event.data.object)
      else
        Rails.logger.info "Unhandled Stripe event type: #{event.type}"
      end

      webhook_event.mark_as_processed!
      render json: { received: true }, status: :ok
    rescue => e
      Rails.logger.error("Error processing webhook event #{event.id}: #{e.message}")
      webhook_event.mark_as_failed!(e.message)
      render json: { error: "Processing failed" }, status: :internal_server_error
    end
  end

  private

  def handle_checkout_completed(session)
    transaction = Transaction.find_by(stripe_checkout_session_id: session.id)
    return unless transaction

    if session.payment_status == "paid" && !transaction.payment_completed?
      transaction.complete_payment!(session.payment_intent)
      Rails.logger.info "Payment completed for transaction #{transaction.id}"
    elsif transaction.payment_completed?
      Rails.logger.info "Payment already completed for transaction #{transaction.id} (idempotency)"
    end
  end

  def handle_payment_succeeded(payment_intent)
    transaction = Transaction.find_by(stripe_payment_intent_id: payment_intent.id)
    return unless transaction

    unless transaction.payment_status == "completed"
      transaction.complete_payment!(payment_intent.id)
      Rails.logger.info "Payment intent succeeded for transaction #{transaction.id}"
    else
      Rails.logger.info "Payment already completed for transaction #{transaction.id} (idempotency)"
    end
  end

  def handle_payment_failed(payment_intent)
    transaction = Transaction.find_by(stripe_payment_intent_id: payment_intent.id)
    return unless transaction

    transaction.update!(payment_status: "failed")
    TransactionMailer.payment_failed(transaction).deliver_later
    Rails.logger.info "Payment failed for transaction #{transaction.id}"
  end

  def handle_connect_account_updated(account)
    user = User.find_by(stripe_connect_account_id: account.id)
    return unless user

    user.update!(
      stripe_connect_onboarded: account.details_submitted,
      stripe_connect_payouts_enabled: account.payouts_enabled
    )
    Rails.logger.info "Connect account updated for user #{user.id}"
  end

  def handle_transfer_created(transfer)
    transaction = Transaction.find_by(stripe_transfer_id: transfer.id)
    return unless transaction

    if transfer.status == "paid" || transfer.status == "pending"
      transaction.update!(payout_status: "completed", payout_at: Time.current)
      Rails.logger.info "Transfer completed for transaction #{transaction.id}"
    end
  end
end
