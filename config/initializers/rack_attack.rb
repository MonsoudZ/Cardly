# Be sure to restart your server when you modify this file.

class Rack::Attack
  # Configure cache store for rate limiting
  # Use Redis in production, memory store in development
  if Rails.env.production?
    self.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
  else
    self.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  # Enable/disable based on environment
  self.enabled = Rails.env.production? || ENV.fetch("RACK_ATTACK_ENABLED", "false") == "true"

  ### Configure Cache ###
  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blocklisting and
  # safelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  ### Throttle Spammy Clients ###
  # If any single client is making too many requests in a given period,
  # reduce that client to a reasonable request rate.
  #
  # Throttle all requests by IP (100 requests per minute)
  throttle("req/ip", limit: 100, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/up", "/assets", "/packs")
  end

  ### Prevent Brute-Force Login Attacks ###
  # Throttle login attempts by IP address
  # Allow 5 login attempts per 20 minutes per IP
  throttle("logins/ip", limit: 5, period: 20.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email address
  # Allow 5 login attempts per 20 minutes per email
  throttle("logins/email", limit: 5, period: 20.minutes) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Extract email from params
      req.params["user"]&.dig("email")&.to_s&.downcase&.gsub(/\s+/, "")
    end
  end

  ### Prevent Brute-Force Password Reset Attacks ###
  # Throttle password reset attempts by IP
  throttle("password_resets/ip", limit: 5, period: 20.minutes) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  ### Throttle Payment Endpoints ###
  # Throttle payment checkout attempts (10 per minute per IP)
  throttle("payments/ip", limit: 10, period: 1.minute) do |req|
    if req.path.match?(%r{/transactions/\d+/payment/checkout}) && req.post?
      req.ip
    end
  end

  # Throttle payment endpoints by user (if authenticated)
  # Note: This requires session access, which may not be available in all contexts
  throttle("payments/user", limit: 20, period: 1.minute) do |req|
    user_id = req.authenticated_user_id
    if req.path.match?(%r{/transactions/\d+/payment}) && user_id
      "user:#{user_id}"
    end
  end

  ### Throttle Webhook Endpoints ###
  # Webhooks should be rate limited more generously but still protected
  throttle("webhooks/ip", limit: 100, period: 1.minute) do |req|
    if req.path == "/webhooks/stripe" && req.post?
      req.ip
    end
  end

  ### Throttle Transaction Creation ###
  # Prevent abuse of transaction creation
  throttle("transactions/create/ip", limit: 20, period: 1.minute) do |req|
    if req.path.match?(%r{/listings/\d+/transactions}) && req.post?
      req.ip
    end
  end

  ### Throttle Admin Actions ###
  # Stricter limits for admin actions
  throttle("admin/ip", limit: 30, period: 1.minute) do |req|
    if req.path.start_with?("/admin")
      req.ip
    end
  end

  ### Custom Response ###
  # Return 429 Too Many Requests for throttled requests
  self.throttled_response = lambda do |env|
    retry_after = (env["rack.attack.match_data"] || {})[:period]
    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{ error: "Too many requests. Please try again later." }.to_json]
    ]
  end

  ### Logging ###
  ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, _request_id, payload|
    req = payload[:request]
    if req.env["rack.attack.match_type"] == :throttle
      Rails.logger.warn "[Rack::Attack] Throttled #{req.env['rack.attack.match_type']} #{req.ip} #{req.request_method} #{req.fullpath}"
    end
  end
end

# Monkey patch to get authenticated user ID for rate limiting
module Rack
  class Request
    def authenticated_user_id
      # Try to get user ID from session
      session = env["rack.session"]
      return nil unless session

      # Devise stores user ID in session["warden.user.user.key"]
      warden_key = session["warden.user.user.key"]
      return nil unless warden_key

      # Extract user ID from warden key format: [[user_id], "encrypted_password"]
      user_id = warden_key.first&.first
      user_id
    end
  end
end
