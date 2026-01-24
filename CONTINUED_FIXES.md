# Continued Deep Audit Fixes Applied
**Date:** January 23, 2026  
**Application:** Cardly - Gift Card Marketplace

This document summarizes all fixes applied from the continued deep audit.

---

## ✅ Priority 1 Fixes (Critical - Completed)

### 1. ✅ Added Pagination to Marketplace Listings
**Location:** `app/controllers/marketplace_controller.rb`, `app/views/marketplace/*.html.erb`

**Issue:** Marketplace listings were not paginated, which could load all active listings into memory.

**Fix Applied:**
- Added `.page(params[:page]).per(24)` to all three marketplace actions (index, sales, trades)
- Updated views to use `@listings.total_count` instead of `@listings.count` for badge counts
- Added pagination links to all marketplace views

**Files Modified:**
- `app/controllers/marketplace_controller.rb`
- `app/views/marketplace/index.html.erb`
- `app/views/marketplace/sales.html.erb`
- `app/views/marketplace/trades.html.erb`

---

### 2. ✅ Added Input Validation to Marketplace Filters
**Location:** `app/controllers/marketplace_controller.rb`

**Issue:** Numeric filter parameters were not validated before use in queries.

**Fix Applied:**
- Added validation for `min_discount` (0-100 range)
- Added validation for `max_price` (must be positive)
- Added validation for `min_value` (must be positive)
- Added validation for `max_value` (must be positive)
- Added validation for `brand_id` (must be positive integer and exist in database)

**Code:**
```ruby
def apply_filters(listings)
  listings = listings.search_brand(params[:q]) if params[:q].present?
  
  # Validate and filter by brand_id
  if params[:brand_id].present?
    brand_id = params[:brand_id].to_i
    listings = listings.by_brand(brand_id) if brand_id > 0 && Brand.exists?(brand_id)
  end
  
  # Validate and filter by min_discount (0-100)
  if params[:min_discount].present?
    min_discount = params[:min_discount].to_f
    listings = listings.min_discount(min_discount) if min_discount >= 0 && min_discount <= 100
  end
  
  # Validate and filter by max_price (must be positive)
  if params[:max_price].present?
    max_price = params[:max_price].to_f
    listings = listings.max_price(max_price) if max_price > 0
  end
  
  # Validate and filter by min_value (must be positive)
  if params[:min_value].present?
    min_value = params[:min_value].to_f
    listings = listings.min_value(min_value) if min_value > 0
  end
  
  # Validate and filter by max_value (must be positive)
  if params[:max_value].present?
    max_value = params[:max_value].to_f
    listings = listings.max_value(max_value) if max_value > 0
  end
  
  listings
end
```

---

### 3. ✅ Added Database Lock to counter! Method
**Location:** `app/models/transaction.rb`

**Issue:** `counter!` method didn't use database lock, allowing race conditions.

**Fix Applied:**
- Wrapped counter logic in `with_lock` block
- Added re-check of status after acquiring lock
- Added error handling with logging

**Code:**
```ruby
def counter!(new_amount, message = nil)
  return false unless pending? && sale?
  return false if new_amount == amount

  with_lock do
    # Re-check status after acquiring lock to prevent race conditions
    return false unless pending?
    
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
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error("Transaction counter failed: #{e.message}")
  false
end
```

---

### 4. ✅ Fixed Strong Parameters in quick_purchase Action
**Location:** `app/controllers/card_activities_controller.rb`

**Issue:** Direct access to params without strong parameters.

**Fix Applied:**
- Created `quick_purchase_params` helper method
- Updated `quick_purchase` action to use strong parameters

**Code:**
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

## ✅ Priority 2 Fixes (High - Completed)

### 5. ✅ Created Transaction Expiration Cleanup Job
**Location:** `app/jobs/transaction_expiration_job.rb` (new file)

**Issue:** No scheduled job to automatically expire transactions that have passed their `expires_at` date.

**Fix Applied:**
- Created `TransactionExpirationJob` class
- Implements expiration for both pending and countered transactions
- Includes error handling and logging

**Code:**
```ruby
class TransactionExpirationJob < ApplicationJob
  queue_as :default

  def perform
    expire_pending_transactions
    expire_countered_transactions
  end

  private

  def expire_pending_transactions
    Transaction.where("expires_at <= ?", Time.current)
               .where(status: "pending")
               .find_each do |transaction|
      begin
        transaction.expire!
        Rails.logger.info "Expired pending transaction #{transaction.id}"
      rescue => e
        Rails.logger.error("Failed to expire transaction #{transaction.id}: #{e.message}")
      end
    end
  end

  def expire_countered_transactions
    Transaction.where("expires_at <= ?", Time.current)
               .where(status: "countered")
               .find_each do |transaction|
      begin
        transaction.expire!
        Rails.logger.info "Expired countered transaction #{transaction.id}"
      rescue => e
        Rails.logger.error("Failed to expire transaction #{transaction.id}: #{e.message}")
      end
    end
  end
end
```

**Note:** This job needs to be scheduled (e.g., with sidekiq-cron) to run hourly or daily.

---

### 6. ✅ Fixed Race Condition in Card Activity Deletion
**Location:** `app/controllers/card_activities_controller.rb`

**Issue:** Used `update_column` which bypasses validations and doesn't use locks.

**Fix Applied:**
- Replaced `update_column` with `update!` inside `with_lock` block
- Added error handling with logging

**Code:**
```ruby
def destroy
  # Restore balance if it was a purchase or refund
  @gift_card.with_lock do
    if @card_activity.purchase?
      @gift_card.update!(balance: @gift_card.balance + @card_activity.amount)
    elsif @card_activity.refund?
      @gift_card.update!(balance: [@gift_card.balance - @card_activity.amount, 0].max)
    end
  end

  @card_activity.destroy
  redirect_to gift_card_card_activities_path(@gift_card), notice: "Activity deleted and balance restored."
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error("Failed to update gift card balance during activity deletion: #{e.message}")
  redirect_to gift_card_card_activities_path(@gift_card), alert: "Could not delete activity: #{e.message}"
end
```

---

## ✅ Priority 3 Fixes (Medium - Completed)

### 7. ✅ Added Scope for User Transactions
**Location:** `app/models/transaction.rb`, `app/controllers/admin/users_controller.rb`

**Issue:** Transaction query for user could use a reusable scope.

**Fix Applied:**
- Added `involving_user` scope to Transaction model
- Updated admin users controller to use the new scope

**Code:**
```ruby
# In Transaction model
scope :involving_user, ->(user) { where("buyer_id = ? OR seller_id = ?", user.id, user.id) }

# In admin users controller
@transactions = Transaction.involving_user(@user)
                          .includes(:buyer, :seller, listing: { gift_card: :brand })
                          .order(created_at: :desc)
                          .limit(10)
```

---

## 📋 Next Steps

### Recommended Actions:

1. **Schedule Transaction Expiration Job:**
   - Add `sidekiq-cron` gem or similar scheduling system
   - Schedule `TransactionExpirationJob` to run hourly or daily

2. **Test Pagination:**
   - Verify pagination works correctly on marketplace pages
   - Test with large datasets

3. **Test Input Validation:**
   - Verify invalid filter parameters are rejected
   - Test edge cases (negative values, out-of-range values)

4. **Monitor Performance:**
   - Watch for any performance improvements from pagination
   - Monitor transaction expiration job execution

---

## 📊 Summary

| Category | Issues Found | Issues Fixed | Status |
|----------|--------------|--------------|--------|
| Pagination | 1 | 1 | ✅ Complete |
| Input Validation | 5 | 5 | ✅ Complete |
| Race Conditions | 2 | 2 | ✅ Complete |
| Strong Parameters | 1 | 1 | ✅ Complete |
| Scheduled Jobs | 1 | 1 | ✅ Complete |
| Code Quality | 1 | 1 | ✅ Complete |
| **Total** | **11** | **11** | ✅ **Complete** |

---

**Report Generated:** January 23, 2026  
**All Priority 1, 2, and 3 items completed**
