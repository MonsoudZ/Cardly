# Production Audit Report - Cardly

**Audit Date:** January 24, 2026  
**Application:** Cardly - Gift Card Marketplace  
**Rails Version:** 8.0  
**Ruby Framework:** Rails with Devise, Stripe, Sidekiq

---

## Executive Summary

This audit examines the Cardly codebase for production readiness. Overall, the application has a solid foundation with good security practices in place, but there are several **critical**, **high**, and **medium** priority issues that should be addressed before production deployment.

| Severity | Count |
|----------|-------|
| 🔴 Critical | 4 |
| 🟠 High | 6 |
| 🟡 Medium | 8 |
| 🔵 Low | 5 |

---

## 🔴 Critical Issues

### 1. Missing Action Mailer Configuration in Production

**File:** `config/environments/production.rb`

**Issue:** No `default_url_options` configured for Action Mailer in production. This will cause all email links (password resets, notifications, etc.) to fail.

**Fix Required:**
```ruby
# Add to config/environments/production.rb
config.action_mailer.default_url_options = { 
  host: ENV.fetch("APP_HOST", "cardly.com"),
  protocol: "https"
}
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  # Configure your SMTP provider
}
```

---

### 2. Devise Mailer Sender Not Configured

**File:** `config/initializers/devise.rb` (Line 27)

**Issue:** The Devise mailer sender is still set to the default placeholder:
```ruby
config.mailer_sender = 'please-change-me-at-config-initializers-devise@example.com'
```

**Fix Required:**
```ruby
config.mailer_sender = ENV.fetch('DEVISE_MAILER_FROM', 'noreply@cardly.com')
```

---

### 3. Content Security Policy Not Enabled

**File:** `config/initializers/content_security_policy.rb`

**Issue:** The entire CSP configuration is commented out, leaving the application vulnerable to XSS attacks, clickjacking, and data injection.

**Fix Required:** Uncomment and configure CSP:
```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data, "*.stripe.com"
    policy.object_src  :none
    policy.script_src  :self, :https, "js.stripe.com"
    policy.style_src   :self, :https, :unsafe_inline
    policy.frame_src   "js.stripe.com", "hooks.stripe.com"
    policy.connect_src :self, :https, "api.stripe.com"
  end
  
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src)
end
```

---

### 4. Missing Database Table for StripeWebhookEvent

**File:** `db/schema.rb`

**Issue:** The `StripeWebhookEvent` model is used but the table is not present in the schema. The migration exists but may not have been run.

**Fix Required:**
```bash
rails db:migrate
```

Verify the table exists with columns: `stripe_event_id`, `event_type`, `payload`, `processed`, `error_message`.

---

## 🟠 High Priority Issues

### 1. Devise Lockable Module Not Enabled

**File:** `app/models/user.rb`

**Issue:** The `:lockable` Devise module is commented out, meaning there's no account lockout after failed login attempts (beyond rate limiting).

**Current:**
```ruby
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable
```

**Recommended Fix:**
```ruby
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable, :lockable
```

Then add migration for lockable fields and configure in `devise.rb`:
```ruby
config.lock_strategy = :failed_attempts
config.unlock_strategy = :time
config.maximum_attempts = 5
config.unlock_in = 30.minutes
```

---

### 2. Paranoid Mode Disabled in Devise

**File:** `config/initializers/devise.rb` (Line 93)

**Issue:** `config.paranoid` is commented out. When disabled, the app reveals whether an email exists in the system during password reset and other flows.

**Fix Required:**
```ruby
config.paranoid = true
```

---

### 3. Missing Production Workers Configuration

**File:** `config/puma.rb`

**Issue:** No worker processes configured for production. Running in single-threaded mode limits concurrency.

**Recommended Fix:**
```ruby
# Add to config/puma.rb
if ENV["RAILS_ENV"] == "production"
  workers ENV.fetch("WEB_CONCURRENCY", 2)
  preload_app!
end
```

---

### 4. Missing stripe_refund_id Column in Schema

**File:** `db/schema.rb`

**Issue:** The `stripe_refund_id` column is referenced in `Dispute#handle_buyer_favor_resolution` but is not present in the schema. The migration exists but may not have been run.

**Fix Required:**
```bash
rails db:migrate
```

---

### 5. Active Storage Using Local Storage in Production

**File:** `config/environments/production.rb` (Line 40)

**Issue:**
```ruby
config.active_storage.service = :local
```

Files stored locally will be lost on container restarts and won't scale across multiple servers.

**Fix Required:**
```ruby
config.active_storage.service = :amazon # or :google, :azure
```

And configure `config/storage.yml` with cloud storage credentials.

---

### 6. Missing require_master_key Setting

**File:** `config/environments/production.rb` (Line 21)

**Issue:** `config.require_master_key` is commented out. Should be enabled to ensure credentials are properly configured.

**Fix Required:**
```ruby
config.require_master_key = true
```

---

## 🟡 Medium Priority Issues

### 1. MarketplaceController Public Access Without Rate Limiting

**File:** `app/controllers/marketplace_controller.rb`

**Issue:** The marketplace endpoints don't require authentication and could be scraped. While Rack::Attack provides general IP-based rate limiting, consider adding additional protection.

**Recommendation:** Add specific marketplace rate limiting:
```ruby
# In rack_attack.rb
throttle("marketplace/ip", limit: 60, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/marketplace")
end
```

---

### 2. Missing Session Timeout

**File:** `config/initializers/devise.rb`

**Issue:** `:timeoutable` module is not enabled. Users remain logged in indefinitely.

**Recommendation:**
```ruby
# In User model
devise :database_authenticatable, ..., :timeoutable

# In devise.rb
config.timeout_in = 30.minutes
```

---

### 3. SQL Injection Risk in Brand Search

**File:** `app/models/listing.rb` (Line 27-28)

**Issue:**
```ruby
scope :search_brand, ->(query) {
  joins(gift_card: :brand).where("brands.name ILIKE ?", "%#{query}%")
}
```

This is properly parameterized, but the ILIKE with wildcards can be slow on large datasets.

**Recommendation:** Add a GiN index for text search:
```ruby
add_index :brands, "name gin_trgm_ops", using: :gin
```

---

### 4. Missing Error Pages for API Endpoints

**Issue:** When returning JSON errors (e.g., in webhooks), HTML error pages may be rendered in some edge cases.

**Recommendation:** Add explicit JSON error handling:
```ruby
# In ApplicationController
rescue_from StandardError, with: :handle_error

def handle_error(exception)
  if request.format.json?
    render json: { error: exception.message }, status: :internal_server_error
  else
    raise exception
  end
end
```

---

### 5. No Cache Store Configured in Production

**File:** `config/environments/production.rb` (Line 71)

**Issue:** Cache store is commented out, defaulting to file store which doesn't work well in multi-server setups.

**Recommendation:**
```ruby
config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
```

---

### 6. Potential N+1 in Transaction#index

**File:** `app/controllers/transactions_controller.rb` (Lines 14-16)

**Issue:**
```ruby
@completed = current_user.purchases.where(status: "completed").or(
  current_user.sales.where(status: "completed")
).includes(listing: { gift_card: :brand }).order(updated_at: :desc).limit(10)
```

The OR query with two different associations may not properly use includes.

**Recommendation:** Consider using a union or separate queries.

---

### 7. Missing Email Confirmation

**File:** `app/models/user.rb`

**Issue:** The `:confirmable` module is not enabled. Users can sign up with any email without verification.

**Recommendation:** Enable confirmable for production:
```ruby
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable, :confirmable
```

---

### 8. Webhook IP Verification

**File:** `app/controllers/webhooks_controller.rb`

**Issue:** While signature verification is in place (good!), Stripe webhook IPs could be additionally whitelisted for defense in depth.

**Recommendation:** Add IP verification in production:
```ruby
STRIPE_WEBHOOK_IPS = %w[
  54.187.174.169 54.187.205.235 54.187.216.72
  # ... Stripe's webhook IP ranges
].freeze

before_action :verify_stripe_ip, only: [:stripe]

def verify_stripe_ip
  unless Rails.env.development? || STRIPE_WEBHOOK_IPS.include?(request.remote_ip)
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
```

---

## 🔵 Low Priority Issues

### 1. Missing Logging for Sensitive Operations

**Recommendation:** Add audit logging for admin actions:
```ruby
after_action :log_admin_action, only: [:toggle_admin, :destroy, :resolve]

def log_admin_action
  Rails.logger.info "[ADMIN] #{current_user.email} performed #{action_name} on #{controller_name}"
end
```

---

### 2. No Database Connection Pool Tuning

**File:** `config/database.yml`

**Issue:** Default pool size may not match thread count.

**Recommendation:**
```yaml
production:
  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 5) %>
```

---

### 3. Missing robots.txt Configuration

**File:** `public/robots.txt`

**Recommendation:** Configure to protect sensitive paths:
```
User-agent: *
Disallow: /admin/
Disallow: /users/
Disallow: /transactions/
Disallow: /disputes/
```

---

### 4. Stripe API Version

**File:** `config/initializers/stripe.rb`

**Issue:** Using API version `2023-10-16` which is not the latest.

**Recommendation:** Consider upgrading to latest Stripe API version and testing thoroughly.

---

### 5. Missing Health Check for Sidekiq

**Recommendation:** Add Sidekiq health monitoring:
```ruby
# Add route
get "health/sidekiq", to: "health#sidekiq"

# Health controller
def sidekiq
  if Sidekiq::ProcessSet.new.size > 0
    render json: { status: "ok" }
  else
    render json: { status: "error", message: "No Sidekiq processes" }, status: :service_unavailable
  end
end
```

---

## ✅ Positive Findings

The following security practices are correctly implemented:

1. **✅ Force SSL enabled** in production
2. **✅ Strong password requirements** (6-128 characters)
3. **✅ Rack::Attack rate limiting** configured for login, passwords, payments, webhooks
4. **✅ Stripe webhook signature verification** with idempotency handling
5. **✅ Sensitive data encryption** for gift card numbers, PINs, barcode data
6. **✅ CSRF protection** enabled (default Rails behavior)
7. **✅ Proper authorization checks** in controllers
8. **✅ Strong parameter filtering** in all controllers
9. **✅ Foreign key constraints** in database
10. **✅ Proper database indexing** for common queries
11. **✅ Transaction locking** for race condition prevention
12. **✅ Request ID logging** enabled
13. **✅ Modern browser requirement** enforced
14. **✅ Sidekiq for async job processing**
15. **✅ Bullet gem** for N+1 detection in development

---

## Deployment Checklist

Before deploying to production, ensure:

- [ ] Run all pending migrations
- [ ] Configure Action Mailer with SMTP provider
- [ ] Update Devise mailer sender email
- [ ] Enable Content Security Policy
- [ ] Set ALLOWED_HOSTS environment variable
- [ ] Configure cloud storage for Active Storage
- [ ] Set up Redis for caching and Sidekiq
- [ ] Configure Puma workers
- [ ] Enable Devise lockable and confirmable modules
- [ ] Set config.require_master_key = true
- [ ] Configure monitoring (APM, error tracking)
- [ ] Set up log aggregation
- [ ] Configure database backups
- [ ] Set up SSL certificates
- [ ] Test webhook endpoints with Stripe CLI
- [ ] Review and update robots.txt
- [ ] Configure CDN for assets (optional)

---

## Summary

The Cardly codebase demonstrates good security practices overall, particularly around payment processing and data protection. However, the 4 critical issues must be resolved before production deployment:

1. Configure Action Mailer for production
2. Update Devise mailer sender
3. Enable Content Security Policy
4. Run pending migrations for webhook events and refunds

The high-priority issues should be addressed in the first production iteration, with medium and low priority items scheduled for subsequent releases.

