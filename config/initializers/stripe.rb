# frozen_string_literal: true

Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key) || ENV["STRIPE_SECRET_KEY"]

# Configure Stripe API version for consistency
Stripe.api_version = "2023-10-16"

# Webhook signing secret for verifying webhook events
Rails.application.config.stripe_webhook_secret =
  Rails.application.credentials.dig(:stripe, :webhook_secret) || ENV["STRIPE_WEBHOOK_SECRET"]

# Platform fee percentage (e.g., 0.05 = 5%)
Rails.application.config.platform_fee_percentage = 0.05
