# Continued Deep Audit Report
**Date:** January 23, 2026  
**Application:** Cardly - Gift Card Marketplace  
**Focus:** Performance, Pagination, Validation, Scheduled Jobs

## Executive Summary

This continued audit identifies additional performance, validation, and operational issues that need attention.

---

## 🔴 Critical Performance Issues

### 1. Missing Pagination on Marketplace Listings
**Severity:** High  
**Location:** `app/controllers/marketplace_controller.rb`

**Issue:** Marketplace listings are not paginated, which could load all active listings into memory.

**Current Code:**
```ruby
def index
  @listings = Listing.active
                     .includes(gift_card: :brand, user: [])
  @listings = apply_filters(@listings)
  @listings = @listings.order(sort_column => sort_direction)
  # No pagination - loads ALL listings
end
```

**Impact:**
- Performance degradation as listings grow
- Memory issues with large datasets
- Slow page loads
- Poor user experience

**Recommendation:**
```ruby
def index
  @listings = Listing.active
                     .includes(gift_card: :brand, user: [])
  @listings = apply_filters(@listings)
  @listings = @listings.order(sort_column => sort_direction)
                       .page(params[:page]).per(24) # Add pagination
  @brands = Brand.active.order(:name)
end
```

---

### 2. Missing Input Validation on Marketplace Filters
**Severity:** Medium  
**Location:** `app/controllers/marketplace_controller.rb:28-35`

**Issue:** Numeric filter parameters are not validated before use in queries.

**Current Code:**
```ruby
def apply_filters(listings)
  listings = listings.min_discount(params[:min_discount]) if params[:min_discount].present?
  listings = listings.max_price(params[:max_price]) if params[:max_price].present?
  listings = listings.min_value(params[:min_value]) if params[:min_value].present?
  listings = listings.max_value(params[:max_value]) if params[:max_value].present?
  listings
end
```

**Impact:**
- Invalid numeric values could cause database errors
- Negative values could return unexpected results
- No bounds checking

**Recommendation:**
```ruby
def apply_filters(listings)
  listings = listings.search_brand(params[:q]) if params[:q].present?
  listings = listings.by_brand(params[:brand_id]) if params[:brand_id].present?
  
  if params[:min_discount].present?
    min_discount = params[:min_discount].to_f
    listings = listings.min_discount(min_discount) if min_discount >= 0 && min_discount <= 100
  end
  
  if params[:max_price].present?
    max_price = params[:max_price].to_f
    listings = listings.max_price(max_price) if max_price > 0
  end
  
  if params[:min_value].present?
    min_value = params[:min_value].to_f
    listings = listings.min_value(min_value) if min_value > 0
  end
  
  if params[:max_value].present?
    max_value = params[:max_value].to_f
    listings = listings.max_value(max_value) if max_value > 0
  end
  
  listings
end
```

---

### 3. Missing Transaction Expiration Cleanup Job
**Severity:** Medium  
**Location:** Application-wide

**Issue:** No scheduled job to automatically expire transactions that have passed their `expires_at` date.

**Current State:**
- `Transaction#expire!` method exists but is never called automatically
- Expired transactions remain in "pending" or "countered" status
- No cleanup mechanism

**Impact:**
- Database accumulates expired transactions
- Users see expired offers as active
- Confusion about transaction status

**Recommendation:**
Create a scheduled job:
```ruby
# app/jobs/transaction_expiration_job.rb
class TransactionExpirationJob < ApplicationJob
  queue_as :default

  def perform
    Transaction.where("expires_at <= ?", Time.current)
               .where(status: %w[pending countered])
               .find_each do |transaction|
      transaction.expire!
    end
  end
end
```

**Schedule:** Run daily or hourly via Sidekiq Cron or similar.

---

### 4. Missing Lock on Counter Method
**Severity:** Medium  
**Location:** `app/models/transaction.rb:216-230`

**Issue:** `counter!` method doesn't use database lock, allowing race conditions.

**Current Code:**
```ruby
def counter!(new_amount, message = nil)
  return false unless pending? && sale?
  return false if new_amount == amount

  update!(status: "countered", ...)
  # No lock - race condition possible
end
```

**Impact:** Multiple counteroffers could be created simultaneously.

**Recommendation:**
```ruby
def counter!(new_amount, message = nil)
  return false unless pending? && sale?
  return false if new_amount == amount

  with_lock do
    return false unless pending? # Re-check after lock
    
    update!(
      original_amount: original_amount || amount,
      counter_amount: new_amount,
      counter_message: message,
      countered_at: Time.current,
      status: "countered",
      expires_at: 48.hours.from_now
    )
    send_counteroffer_notification
    true
  end
end
```

---

### 5. Missing Strong Parameters in Quick Purchase
**Severity:** Medium  
**Location:** `app/controllers/card_activities_controller.rb:57-73`

**Issue:** Direct access to params without strong parameters.

**Current Code:**
```ruby
def quick_purchase
  @card_activity = @gift_card.card_activities.build(
    activity_type: "purchase",
    amount: params[:amount],
    merchant: params[:merchant],
    occurred_at: Time.current
  )
  # ...
end
```

**Recommendation:**
```ruby
def quick_purchase
  @card_activity = @gift_card.card_activities.build(
    quick_purchase_params.merge(
      activity_type: "purchase",
      occurred_at: Time.current
    )
  )
  # ...
end

private

def quick_purchase_params
  params.permit(:amount, :merchant)
end
```

---

### 6. Race Condition in Card Activity Deletion
**Severity:** Medium  
**Location:** `app/controllers/card_activities_controller.rb:44-54`

**Issue:** Uses `update_column` which bypasses validations and doesn't use locks.

**Current Code:**
```ruby
def destroy
  if @card_activity.purchase?
    @gift_card.update_column(:balance, @gift_card.balance + @card_activity.amount)
  elsif @card_activity.refund?
    @gift_card.update_column(:balance, [@gift_card.balance - @card_activity.amount, 0].max)
  end
  @card_activity.destroy
end
```

**Impact:** Balance could be incorrect with concurrent deletions.

**Recommendation:**
```ruby
def destroy
  @gift_card.with_lock do
    if @card_activity.purchase?
      @gift_card.update!(balance: @gift_card.balance + @card_activity.amount)
    elsif @card_activity.refund?
      @gift_card.update!(balance: [@gift_card.balance - @card_activity.amount, 0].max)
    end
  end
  @card_activity.destroy
end
```

---

## 🟡 Performance Recommendations

### 7. Missing Limit on Admin Dashboard Queries
**Severity:** Low  
**Location:** `app/controllers/admin/dashboard_controller.rb:34-36`

**Issue:** Weekly transactions query groups by date without limit.

**Current Code:**
```ruby
@weekly_transactions = Transaction.where("created_at >= ?", 7.days.ago)
                                   .group("DATE(created_at)")
                                   .count
```

**Status:** ✅ Acceptable - Limited to 7 days, but could be optimized.

**Recommendation:** Consider caching this data or limiting to specific date range.

---

### 8. Missing Scope for User Transactions
**Severity:** Low  
**Location:** `app/controllers/admin/users_controller.rb:25`

**Issue:** Transaction query could use a reusable scope.

**Recommendation:**
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

### 9. Missing Validation on Brand ID Filter
**Severity:** Low  
**Location:** `app/controllers/marketplace_controller.rb:30`

**Issue:** `brand_id` parameter not validated before use.

**Recommendation:**
```ruby
def apply_filters(listings)
  listings = listings.search_brand(params[:q]) if params[:q].present?
  
  if params[:brand_id].present?
    brand_id = params[:brand_id].to_i
    listings = listings.by_brand(brand_id) if brand_id > 0 && Brand.exists?(brand_id)
  end
  # ...
end
```

---

## 🟢 Code Quality Issues

### 10. Missing Error Handling in Card Activity Balance Update
**Severity:** Low  
**Location:** `app/models/card_activity.rb:77-95`

**Status:** ✅ Good - Error handling was added in previous fix.

---

### 11. Missing Authorization Check on Ratings
**Severity:** Low  
**Location:** `app/controllers/ratings_controller.rb`

**Status:** ✅ Good - Uses `ensure_can_rate` before_action which checks authorization.

---

## 📋 Operational Recommendations

### 12. Scheduled Jobs Configuration
**Severity:** Medium  
**Location:** Application-wide

**Issue:** No job scheduling system configured.

**Recommendations:**
- Add `sidekiq-cron` or `whenever` gem for scheduled jobs
- Schedule:
  - `ExpirationReminderJob` - Daily
  - `TransactionExpirationJob` - Hourly (new)
  - Cleanup jobs for old data

**Example with sidekiq-cron:**
```ruby
# config/initializers/sidekiq_cron.rb
Sidekiq::Cron::Job.create(
  name: 'Expiration Reminders - Daily',
  cron: '0 9 * * *', # 9 AM daily
  class: 'ExpirationReminderJob'
)

Sidekiq::Cron::Job.create(
  name: 'Transaction Expiration - Hourly',
  cron: '0 * * * *', # Every hour
  class: 'TransactionExpirationJob'
)
```

---

### 13. Missing Database Query Timeout Configuration
**Severity:** Low  
**Location:** `config/database.yml`

**Recommendation:** Add query timeout for production:
```yaml
production:
  # ...
  variables:
    statement_timeout: 5000 # 5 seconds
```

---

## ✅ Positive Findings

1. **Good Use of Scopes** - Models have well-defined scopes
2. **Good Eager Loading** - Most queries use `.includes()`
3. **Good Authorization** - Proper checks in place
4. **Good Error Handling** - Most critical paths have error handling

---

## 🔧 Immediate Action Items

### Priority 1 (Critical - Fix Immediately)
1. ✅ Add pagination to marketplace listings
2. ✅ Add input validation to marketplace filters
3. ✅ Add lock to counter! method
4. ✅ Fix strong parameters in quick_purchase

### Priority 2 (High - Fix Soon)
5. ✅ Create transaction expiration job
6. ✅ Fix race condition in card activity deletion
7. ✅ Add job scheduling system

### Priority 3 (Medium - Plan for Next Sprint)
8. ✅ Add scope for user transactions
9. ✅ Validate brand_id filter
10. ✅ Configure database query timeouts

---

## 📊 Updated Score

| Category | Score | Status |
|----------|-------|--------|
| Performance | 6/10 | ⚠️ Needs Improvement |
| Pagination | 3/10 | 🔴 Critical |
| Input Validation | 7/10 | ⚠️ Needs Improvement |
| Scheduled Jobs | 2/10 | 🔴 Critical |
| **Overall** | **4.5/10** | ⚠️ **Needs Improvement** |

---

**Report Generated:** January 23, 2026  
**Next Review:** After implementing Priority 1 & 2 items
