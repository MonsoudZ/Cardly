# Follow-Up Security Audit Report
**Date:** January 23, 2026  
**Application:** Cardly - Gift Card Marketplace  
**Previous Audit:** Initial audit completed, Priority 1 & 2 fixes applied

## Executive Summary

This follow-up audit identifies additional security and code quality issues that were not addressed in the initial audit. The application has significantly improved security posture, but several areas still need attention.

---

## 🔴 Critical Issues Found

### 1. Missing Strong Parameters in Admin Disputes Controller
**Severity:** High  
**Location:** `app/controllers/admin/disputes_controller.rb`

**Issue:** Direct access to `params` without strong parameters in multiple actions:

```ruby
# Line 48-49: resolve action
resolution = params[:resolution]
resolution_notes = params[:resolution_notes]

# Line 61: close action
admin_notes = params[:admin_notes]

# Line 83: add_message action
content: params[:dispute_message][:content]
```

**Impact:** Vulnerable to mass assignment attacks and parameter injection.

**Recommendation:**
```ruby
def resolve
  if @dispute.resolve!(dispute_resolution_params[:resolution], 
                       dispute_resolution_params[:resolution_notes], 
                       current_user)
    # ...
  end
end

def close
  if @dispute.close!(dispute_close_params[:admin_notes])
    # ...
  end
end

def add_message
  @message = @dispute.dispute_messages.new(
    dispute_message_params.merge(
      sender: current_user,
      is_admin_message: true
    )
  )
  # ...
end

private

def dispute_resolution_params
  params.permit(:resolution, :resolution_notes)
end

def dispute_close_params
  params.permit(:admin_notes)
end

def dispute_message_params
  params.require(:dispute_message).permit(:content)
end
```

---

### 2. Missing Background Job Queue Adapter Configuration
**Severity:** High  
**Location:** `config/environments/production.rb:74-75`

**Issue:** Active Job queue adapter is commented out, meaning background jobs will not be processed in production.

```ruby
# config.active_job.queue_adapter = :resque
```

**Impact:** 
- Expiration reminder emails will not be sent
- Transaction notification emails will not be sent
- Price drop alerts will not be sent
- All `deliver_later` calls will fail silently or use default adapter

**Recommendation:**
- Configure a production-ready queue adapter (Sidekiq, Delayed Job, Good Job, etc.)
- Example with Sidekiq:
  ```ruby
  config.active_job.queue_adapter = :sidekiq
  ```
- Ensure queue workers are running in production
- Monitor job processing

---

## 🟡 Security Recommendations

### 3. XSS Risk in View Components
**Severity:** Medium  
**Location:** `app/views/shared/components/_icon.html.erb:83`, `_button.html.erb:66`, `_alert.html.erb:72`

**Issue:** Use of `html_safe` on potentially user-controlled data:

```ruby
<%= icon_path.html_safe %>
<%= data.map { |k, v| "data-#{k}=\"#{v}\"" }.join(' ').html_safe %>
<%= icons[variant].html_safe %>
```

**Impact:** If these values come from user input, XSS attacks are possible.

**Status:** ⚠️ Needs Review
- Verify that `icon_path`, `data`, and `icons[variant]` are not user-controlled
- If they are, use `sanitize()` or `h()` instead of `html_safe`
- Consider using Rails' built-in helpers for data attributes

**Recommendation:**
- Audit all uses of `html_safe` to ensure no user input
- Use `sanitize()` for user-generated content
- Prefer Rails helpers like `tag.data()` for data attributes

---

### 4. Missing Input Validation on Admin Dispute Actions
**Severity:** Medium  
**Location:** `app/controllers/admin/disputes_controller.rb:47-58`

**Issue:** No validation that `resolution` parameter is a valid value before passing to model.

**Current Code:**
```ruby
def resolve
  resolution = params[:resolution]
  resolution_notes = params[:resolution_notes]
  
  if @dispute.resolve!(resolution, resolution_notes, current_user)
    # ...
  end
end
```

**Recommendation:**
```ruby
def resolve
  resolution = params[:resolution]
  unless Dispute::RESOLUTIONS.include?(resolution)
    redirect_to admin_dispute_path(@dispute),
                alert: "Invalid resolution type."
    return
  end
  
  if @dispute.resolve!(resolution, params[:resolution_notes], current_user)
    # ...
  end
end
```

**Note:** The model method `resolve!` does validate this, but it's better to validate at the controller level for better error messages.

---

### 5. Missing Authorization Check on Admin Actions
**Severity:** Low  
**Location:** `app/controllers/admin/disputes_controller.rb`

**Status:** ✅ Good - All admin controllers inherit from `Admin::BaseController` which has `require_admin!` before_action.

**Note:** This is already properly secured, but worth verifying.

---

## 🟢 Code Quality Issues

### 6. Potential N+1 Query in Admin Users Controller
**Severity:** Low  
**Location:** `app/controllers/admin/users_controller.rb:25`

**Issue:** Transaction query could be optimized:

```ruby
@transactions = Transaction.where("buyer_id = ? OR seller_id = ?", @user.id, @user.id)
                          .includes(:buyer, :seller, listing: { gift_card: :brand })
                          .order(created_at: :desc)
                          .limit(10)
```

**Status:** ✅ Good - Already uses `.includes()` for eager loading.

**Recommendation:** Consider using a scope for better reusability:
```ruby
# In Transaction model
scope :involving_user, ->(user) { 
  where("buyer_id = ? OR seller_id = ?", user.id, user.id) 
}

# In controller
@transactions = Transaction.involving_user(@user)
                          .includes(:buyer, :seller, listing: { gift_card: :brand })
                          .order(created_at: :desc)
                          .limit(10)
```

---

### 7. Missing Error Handling for Stripe API Calls
**Severity:** Low  
**Location:** `app/controllers/stripe_connect_controller.rb`

**Status:** ✅ Good - All Stripe API calls are wrapped in `rescue Stripe::StripeError` blocks.

---

### 8. User Input in Search Query
**Severity:** Low  
**Location:** `app/controllers/admin/users_controller.rb:10-11`

**Issue:** User input used in SQL query:

```ruby
search = "%#{params[:search]}%"
@users = @users.where("email ILIKE ? OR name ILIKE ?", search, search)
```

**Status:** ✅ Safe - Uses parameterized queries, so SQL injection is not possible.

**Note:** This is correctly implemented. The `%` wildcards are added to the Ruby string before passing to the query, which is safe.

---

## 📋 Operational Issues

### 9. Background Job Processing
**Severity:** High  
**Location:** Multiple files using `deliver_later`

**Issue:** No queue adapter configured for production.

**Files Affected:**
- `app/jobs/expiration_reminder_job.rb`
- `app/models/transaction.rb` (multiple `deliver_later` calls)
- `app/models/listing.rb` (price drop notifications)
- `app/models/dispute.rb` (dispute notifications)

**Impact:** All background jobs will fail or not execute in production.

**Recommendation:**
1. Choose a queue adapter (Sidekiq recommended for Rails 8)
2. Add gem to Gemfile: `gem "sidekiq"`
3. Configure in production:
   ```ruby
   config.active_job.queue_adapter = :sidekiq
   ```
4. Set up Redis for Sidekiq
5. Add Sidekiq web UI for monitoring (optional)
6. Ensure Sidekiq process runs in production

---

### 10. Missing Monitoring and Error Tracking
**Severity:** Medium  
**Location:** Application-wide

**Issue:** No application monitoring or error tracking service configured.

**Recommendation:**
- Add Sentry or Rollbar for error tracking
- Add performance monitoring (New Relic, Skylight, etc.)
- Set up structured logging
- Configure alerting for critical errors

---

## ✅ Positive Findings

1. **Good Authorization Patterns** - Admin routes properly protected
2. **Proper Use of Strong Parameters** - Most controllers use strong parameters correctly
3. **Good Error Handling** - Stripe errors are properly caught
4. **Good Query Optimization** - Eager loading used appropriately
5. **Good Validation** - Models have comprehensive validations
6. **Encryption** - Sensitive fields properly encrypted
7. **Rate Limiting** - Implemented with Rack::Attack
8. **Host Authorization** - Configured for production

---

## 🔧 Immediate Action Items

### Priority 1 (Critical - Fix Immediately)
1. ✅ Fix strong parameters in Admin::DisputesController
2. ✅ Configure background job queue adapter for production
3. ✅ Review and secure `html_safe` usage in views

### Priority 2 (High - Fix Soon)
4. ✅ Add input validation to admin dispute actions
5. ✅ Set up monitoring and error tracking
6. ✅ Test background job processing

### Priority 3 (Medium - Plan for Next Sprint)
7. ✅ Optimize admin queries with scopes
8. ✅ Add integration tests for admin actions
9. ✅ Document background job setup

---

## 📊 Updated Security Score

| Category | Previous | Current | Status |
|----------|----------|---------|--------|
| Authentication & Authorization | 9/10 | 9/10 | ✅ Excellent |
| Data Encryption | 7/10 | 9/10 | ✅ Excellent |
| Input Validation | 8/10 | 8/10 | ⚠️ Needs Improvement |
| Logging & Monitoring | 6/10 | 6/10 | ⚠️ Needs Improvement |
| Rate Limiting | 0/10 | 9/10 | ✅ Excellent |
| Error Handling | 8/10 | 8/10 | ✅ Good |
| Background Jobs | 3/10 | 3/10 | 🔴 Critical |
| **Overall** | **7.3/10** | **7.4/10** | ⚠️ **Good with Critical Issues** |

---

## Summary

The application has made significant security improvements from the initial audit. However, two critical issues remain:

1. **Background jobs will not work in production** - This is a critical operational issue that will break email notifications and reminders.

2. **Strong parameters missing in admin controller** - This is a security vulnerability that should be fixed immediately.

Once these are addressed, the application will be in excellent shape for production deployment.

---

**Report Generated:** January 23, 2026  
**Next Review:** After implementing Priority 1 items
