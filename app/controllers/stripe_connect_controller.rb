class StripeConnectController < ApplicationController
  before_action :authenticate_user!

  # GET /connect/onboard
  # Start the Stripe Connect onboarding flow for sellers
  def onboard
    # Create or retrieve Connect account
    if current_user.stripe_connect_account_id.blank?
      account = Stripe::Account.create(
        type: "express",
        country: "US",
        email: current_user.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true }
        },
        metadata: { user_id: current_user.id }
      )
      current_user.update!(stripe_connect_account_id: account.id)
    end

    # Create account link for onboarding
    account_link = Stripe::AccountLink.create(
      account: current_user.stripe_connect_account_id,
      refresh_url: stripe_connect_refresh_url,
      return_url: stripe_connect_return_url,
      type: "account_onboarding"
    )

    redirect_to account_link.url, allow_other_host: true
  rescue Stripe::StripeError => e
    flash[:alert] = "Error setting up seller account: #{e.message}"
    redirect_to profile_path
  end

  # GET /connect/return
  # User returns from Stripe Connect onboarding
  def return
    if current_user.stripe_connect_account_id.present?
      # Check account status
      account = Stripe::Account.retrieve(current_user.stripe_connect_account_id)

      current_user.update!(
        stripe_connect_onboarded: account.details_submitted,
        stripe_connect_payouts_enabled: account.payouts_enabled
      )

      if account.details_submitted
        flash[:notice] = "Your seller account has been set up successfully! You can now receive payments."
      else
        flash[:alert] = "Your seller account setup is incomplete. Please complete all required information."
      end
    end

    redirect_to profile_path
  rescue Stripe::StripeError => e
    flash[:alert] = "Error checking account status: #{e.message}"
    redirect_to profile_path
  end

  # GET /connect/refresh
  # Refresh the onboarding link if it expired
  def refresh
    if current_user.stripe_connect_account_id.blank?
      redirect_to stripe_connect_onboard_path
      return
    end

    account_link = Stripe::AccountLink.create(
      account: current_user.stripe_connect_account_id,
      refresh_url: stripe_connect_refresh_url,
      return_url: stripe_connect_return_url,
      type: "account_onboarding"
    )

    redirect_to account_link.url, allow_other_host: true
  rescue Stripe::StripeError => e
    flash[:alert] = "Error refreshing onboarding link: #{e.message}"
    redirect_to profile_path
  end
end
