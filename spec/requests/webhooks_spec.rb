require 'rails_helper'

RSpec.describe "Webhooks", type: :request do
  let(:webhook_secret) { "whsec_test123" }

  before do
    allow(Rails.application.config).to receive(:stripe_webhook_secret).and_return(webhook_secret)
  end

  describe "POST /webhooks/stripe" do
    let(:buyer) { create(:user) }
    let(:seller) { create(:user, stripe_connect_account_id: "acct_test456") }
    let(:gift_card) { create(:gift_card, user: seller, balance: 100.00) }
    let(:listing) { create(:listing, gift_card: gift_card, user: seller, status: "active") }
    let(:transaction) do
      create(:transaction,
        buyer: buyer,
        seller: seller,
        listing: listing,
        transaction_type: "sale",
        amount: 80.00,
        status: "accepted",
        payment_status: "pending",
        stripe_checkout_session_id: "cs_test123"
      )
    end

    def generate_signature(payload)
      timestamp = Time.now.to_i
      signed_payload = "#{timestamp}.#{payload}"
      signature = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, signed_payload)
      "t=#{timestamp},v1=#{signature}"
    end

    context "checkout.session.completed event" do
      it "completes the payment" do
        # Ensure transaction exists before webhook is processed
        transaction

        event_payload = {
          id: "evt_test123",
          type: "checkout.session.completed",
          data: {
            object: {
              id: "cs_test123",
              payment_status: "paid",
              payment_intent: "pi_test123"
            }
          }
        }.to_json

        allow(Stripe::Webhook).to receive(:construct_event).and_return(
          Stripe::Event.construct_from(JSON.parse(event_payload))
        )
        allow_any_instance_of(Transaction).to receive(:initiate_seller_payout)

        post webhooks_stripe_path,
          params: event_payload,
          headers: {
            "HTTP_STRIPE_SIGNATURE" => generate_signature(event_payload),
            "CONTENT_TYPE" => "application/json"
          }

        expect(response).to have_http_status(:ok)
        expect(transaction.reload.payment_status).to eq("completed")
      end
    end

    context "payment_intent.payment_failed event" do
      it "marks payment as failed" do
        transaction.update!(stripe_payment_intent_id: "pi_test123")

        event_payload = {
          id: "evt_test456",
          type: "payment_intent.payment_failed",
          data: {
            object: {
              id: "pi_test123"
            }
          }
        }.to_json

        allow(Stripe::Webhook).to receive(:construct_event).and_return(
          Stripe::Event.construct_from(JSON.parse(event_payload))
        )

        post webhooks_stripe_path,
          params: event_payload,
          headers: {
            "HTTP_STRIPE_SIGNATURE" => generate_signature(event_payload),
            "CONTENT_TYPE" => "application/json"
          }

        expect(response).to have_http_status(:ok)
        expect(transaction.reload.payment_status).to eq("failed")
      end
    end

    context "account.updated event" do
      it "updates user connect account status" do
        # Ensure seller exists before webhook is processed
        seller

        event_payload = {
          id: "evt_test789",
          type: "account.updated",
          data: {
            object: {
              id: "acct_test456",
              details_submitted: true,
              payouts_enabled: true
            }
          }
        }.to_json

        allow(Stripe::Webhook).to receive(:construct_event).and_return(
          Stripe::Event.construct_from(JSON.parse(event_payload))
        )

        post webhooks_stripe_path,
          params: event_payload,
          headers: {
            "HTTP_STRIPE_SIGNATURE" => generate_signature(event_payload),
            "CONTENT_TYPE" => "application/json"
          }

        expect(response).to have_http_status(:ok)
        seller.reload
        expect(seller.stripe_connect_onboarded).to be true
        expect(seller.stripe_connect_payouts_enabled).to be true
      end
    end

    context "with invalid signature" do
      it "returns bad request" do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(
          Stripe::SignatureVerificationError.new("Invalid signature", "sig_header")
        )

        post webhooks_stripe_path,
          params: { type: "checkout.session.completed" }.to_json,
          headers: {
            "HTTP_STRIPE_SIGNATURE" => "invalid",
            "CONTENT_TYPE" => "application/json"
          }

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with invalid JSON" do
      it "returns bad request" do
        allow(Stripe::Webhook).to receive(:construct_event).and_raise(
          JSON::ParserError.new("Invalid JSON")
        )

        post webhooks_stripe_path,
          params: "invalid json",
          headers: {
            "HTTP_STRIPE_SIGNATURE" => "t=123,v1=abc",
            "CONTENT_TYPE" => "application/json"
          }

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
