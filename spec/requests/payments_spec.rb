require 'rails_helper'

RSpec.describe "Payments", type: :request do
  let(:buyer) { create(:user, stripe_customer_id: "cus_test123") }
  let(:seller) { create(:user, stripe_connect_account_id: "acct_test456", stripe_connect_onboarded: true, stripe_connect_payouts_enabled: true) }
  let(:gift_card) { create(:gift_card, user: seller, balance: 100.00) }
  let(:listing) { create(:listing, gift_card: gift_card, user: seller, asking_price: 85.00, status: "active") }
  let(:transaction) do
    create(:transaction,
      buyer: buyer,
      seller: seller,
      listing: listing,
      transaction_type: "sale",
      amount: 80.00,
      status: "accepted",
      payment_status: "unpaid"
    )
  end

  describe "POST /transactions/:transaction_id/payment/checkout" do
    context "when not logged in" do
      it "redirects to login" do
        post checkout_transaction_payment_path(transaction)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in as buyer" do
      before { sign_in buyer }

      it "creates a Stripe checkout session and redirects", :vcr do
        # Mock Stripe API
        allow(Stripe::Customer).to receive(:create).and_return(
          double(id: "cus_new123")
        )

        checkout_session = double(
          id: "cs_test123",
          url: "https://checkout.stripe.com/test",
          payment_intent: "pi_test123"
        )
        allow(Stripe::Checkout::Session).to receive(:create).and_return(checkout_session)

        post checkout_transaction_payment_path(transaction)

        expect(response).to redirect_to("https://checkout.stripe.com/test")
        expect(transaction.reload.stripe_checkout_session_id).to eq("cs_test123")
        expect(transaction.payment_status).to eq("pending")
      end

      it "calculates correct payment amounts" do
        checkout_session = double(
          id: "cs_test123",
          url: "https://checkout.stripe.com/test"
        )
        allow(Stripe::Checkout::Session).to receive(:create).and_return(checkout_session)

        post checkout_transaction_payment_path(transaction)

        transaction.reload
        expect(transaction.payment_amount_cents).to eq(8000) # $80.00
        expect(transaction.platform_fee_cents).to eq(400) # 5% of $80
        expect(transaction.seller_payout_cents).to eq(7600) # $80 - $4
      end
    end

    context "when logged in as seller" do
      before { sign_in seller }

      it "denies access" do
        post checkout_transaction_payment_path(transaction)
        expect(response).to redirect_to(transactions_path)
        expect(flash[:alert]).to include("not authorized")
      end
    end

    context "when transaction is not accepted" do
      before do
        sign_in buyer
        transaction.update!(status: "pending")
      end

      it "denies checkout" do
        post checkout_transaction_payment_path(transaction)
        expect(response).to redirect_to(transaction_path(transaction))
        expect(flash[:alert]).to include("not ready for payment")
      end
    end

    context "when transaction is already paid" do
      before do
        sign_in buyer
        transaction.update!(payment_status: "completed")
      end

      it "redirects with notice" do
        post checkout_transaction_payment_path(transaction)
        expect(response).to redirect_to(transaction_path(transaction))
        expect(flash[:notice]).to include("already been paid")
      end
    end
  end

  describe "GET /transactions/:transaction_id/payment/success" do
    before { sign_in buyer }

    it "completes payment when session is valid" do
      transaction.update!(stripe_checkout_session_id: "cs_test123", payment_status: "pending")

      stripe_session = double(
        payment_status: "paid",
        payment_intent: "pi_test123"
      )
      allow(Stripe::Checkout::Session).to receive(:retrieve).and_return(stripe_session)

      # Mock the complete_payment! method's Stripe calls
      allow_any_instance_of(Transaction).to receive(:initiate_seller_payout)

      get success_transaction_payment_path(transaction, session_id: "cs_test123")

      expect(response).to redirect_to(transaction_path(transaction))
      expect(flash[:notice]).to include("Payment successful")
      expect(transaction.reload.payment_status).to eq("completed")
    end

    it "shows error for invalid session" do
      transaction.update!(stripe_checkout_session_id: "cs_other")

      get success_transaction_payment_path(transaction, session_id: "cs_wrong")

      expect(response).to redirect_to(transaction_path(transaction))
      expect(flash[:alert]).to include("Invalid payment session")
    end
  end

  describe "GET /transactions/:transaction_id/payment/cancel" do
    before do
      sign_in buyer
      transaction.update!(payment_status: "pending")
    end

    it "cancels the payment" do
      get cancel_transaction_payment_path(transaction)

      expect(response).to redirect_to(transaction_path(transaction))
      expect(flash[:notice]).to include("cancelled")
      expect(transaction.reload.payment_status).to eq("cancelled")
    end
  end
end
