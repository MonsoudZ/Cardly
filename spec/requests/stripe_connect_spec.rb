require 'rails_helper'

RSpec.describe "StripeConnect", type: :request do
  let(:user) { create(:user) }

  describe "GET /connect/onboard" do
    context "when not logged in" do
      it "redirects to login" do
        get stripe_connect_onboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when logged in" do
      before { sign_in user }

      it "creates a connect account and redirects to Stripe" do
        account = double(id: "acct_test123")
        allow(Stripe::Account).to receive(:create).and_return(account)

        account_link = double(url: "https://connect.stripe.com/setup/test")
        allow(Stripe::AccountLink).to receive(:create).and_return(account_link)

        get stripe_connect_onboard_path

        expect(response).to redirect_to("https://connect.stripe.com/setup/test")
        expect(user.reload.stripe_connect_account_id).to eq("acct_test123")
      end

      it "uses existing connect account if present" do
        user.update!(stripe_connect_account_id: "acct_existing")

        account_link = double(url: "https://connect.stripe.com/setup/existing")
        allow(Stripe::AccountLink).to receive(:create).and_return(account_link)

        expect(Stripe::Account).not_to receive(:create)

        get stripe_connect_onboard_path

        expect(response).to redirect_to("https://connect.stripe.com/setup/existing")
      end

      it "handles Stripe errors gracefully" do
        allow(Stripe::Account).to receive(:create).and_raise(
          Stripe::StripeError.new("Something went wrong")
        )

        get stripe_connect_onboard_path

        expect(response).to redirect_to(profile_path)
        expect(flash[:alert]).to include("Error")
      end
    end
  end

  describe "GET /connect/return" do
    before { sign_in user }

    context "when account is fully set up" do
      it "updates user and shows success" do
        user.update!(stripe_connect_account_id: "acct_test123")

        account = double(
          details_submitted: true,
          payouts_enabled: true
        )
        allow(Stripe::Account).to receive(:retrieve).and_return(account)

        get stripe_connect_return_path

        expect(response).to redirect_to(profile_path)
        expect(flash[:notice]).to include("successfully")

        user.reload
        expect(user.stripe_connect_onboarded).to be true
        expect(user.stripe_connect_payouts_enabled).to be true
      end
    end

    context "when account setup is incomplete" do
      it "shows incomplete message" do
        user.update!(stripe_connect_account_id: "acct_test123")

        account = double(
          details_submitted: false,
          payouts_enabled: false
        )
        allow(Stripe::Account).to receive(:retrieve).and_return(account)

        get stripe_connect_return_path

        expect(response).to redirect_to(profile_path)
        expect(flash[:alert]).to include("incomplete")
      end
    end
  end

  describe "GET /connect/refresh" do
    before { sign_in user }

    it "redirects to onboard if no connect account" do
      get stripe_connect_refresh_path
      expect(response).to redirect_to(stripe_connect_onboard_path)
    end

    it "creates new account link if connect account exists" do
      user.update!(stripe_connect_account_id: "acct_test123")

      account_link = double(url: "https://connect.stripe.com/setup/refresh")
      allow(Stripe::AccountLink).to receive(:create).and_return(account_link)

      get stripe_connect_refresh_path

      expect(response).to redirect_to("https://connect.stripe.com/setup/refresh")
    end
  end
end
