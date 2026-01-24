# Deep Dive Security & Data Integrity Audit
**Date:** January 23, 2026  
**Application:** Cardly - Gift Card Marketplace  
**Focus:** Race Conditions, Data Integrity, Edge Cases

## Executive Summary

This deep dive audit focuses on race conditions, data integrity issues, and edge cases that could lead to financial losses, data corruption, or security vulnerabilities. Several critical issues were identified that need immediate attention.

---

## 🔴 Critical Data Integrity Issues

### 1. Race Condition in Transaction Acceptance
**Severity:** Critical  
**Location:** `app/models/transaction.rb:163-183`, `app/models/transaction.rb:215-238`

**Issue:** The `accept!` and `accept_counter!` methods don't use database locks, allowing concurrent requests to accept the same transaction multiple times.

**Current Code:**
```ruby
def accept!
  return false unless pending?
  # No lock - race condition possible
  if sale?
    update!(status: "accepted")
    # ...
  end
end
```

**Impact:** 
- Same transaction could be accepted multiple times
- Gift card could be transferred to multiple buyers
- Financial loss and data corruption

**Recommendation:**
```ruby
def accept!
  return false unless pending?
  
  with_lock do
    return false unless pending? # Re-check after acquiring lock
    
    if sale?
      update!(status: "accepted")
      # ...
    else
      ActiveRecord::Base.transaction do
        complete_transaction!
      end
    end
    true
  end
rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
  Rails.logger.error("Transaction accept failed: #{e.message}")
  false
end
```

---

### 2. Missing Idempotency Check in Payment Completion
**Severity:** Critical  
**Location:** `app/models/transaction.rb:240-257`, `app/controllers/webhooks_controller.rb:42-60`

**Issue:** `complete_payment!` doesn't verify if payment was already completed, and webhook handlers don't check for duplicate events.

**Current Code:**
```ruby
def complete_payment!(payment_intent_id)
  return false unless accepted? && sale?
  # No check if already completed
  
  ActiveRecord::Base.transaction do
    update!(payment_status: "completed", ...)
    complete_transaction!
  end
end
```

**Impact:**
- Stripe can send duplicate webhook events
- Payment could be processed multiple times
- Gift card transferred multiple times
- Financial discrepancies

**Recommendation:**
```ruby
def complete_payment!(payment_intent_id)
  return false unless accepted? && sale?
  return false if payment_completed? # Idempotency check
  
  with_lock do
    return false if payment_completed? # Re-check after lock
    
    ActiveRecord::Base.transaction do
      update!(
        stripe_payment_intent_id: payment_intent_id,
        payment_status: "completed",
        paid_at: Time.current
      )
      complete_transaction!
      initiate_seller_payout if seller.stripe_connect_payouts_enabled?
    end
    send_payment_completed_notification
    true
  end
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.error("Complete payment failed: #{e.message}")
  false
end
```

**Webhook Handler:**
```ruby
def handle_checkout_completed(session)
  transaction = Transaction.find_by(stripe_checkout_session_id: session.id)
  return unless transaction
  
  if session.payment_status == "paid" && !transaction.payment_completed?
    transaction.complete_payment!(session.payment_intent)
  end
end
```

---

### 3. Race Condition in Gift Card Balance Updates
**Severity:** High  
**Location:** `app/models/card_activity.rb:77-81`

**Issue:** Balance updates use `update_column` which bypasses validations and doesn't use locks, leading to race conditions.

**Current Code:**
```ruby
def update_gift_card_balance
  return unless balance_after && gift_card
  
  gift_card.update_column(:balance, balance_after)
end
```

**Impact:**
- Concurrent card activities could result in incorrect balances
- Balance could go negative
- Data integrity issues

**Recommendation:**
```ruby
def update_gift_card_balance
  return unless balance_after && gift_card
  
  gift_card.with_lock do
    # Recalculate from all activities to ensure accuracy
    calculated_balance = gift_card.card_activities
                                  .where("occurred_at <= ?", occurred_at)
                                  .sum { |a| a.signed_amount }
    
    gift_card.update!(balance: [calculated_balance, 0].max)
  end
end
```

**Alternative:** Use database-level balance calculation or optimistic locking.

---

### 4. Missing Validation in Transaction Completion
**Severity:** High  
**Location:** `app/models/transaction.rb:305-327`

**Issue:** `complete_sale!` and `complete_trade!` don't verify that listing is still active or that gift card hasn't been transferred.

**Current Code:**
```ruby
def complete_sale!
  gift_card = listing.gift_card
  gift_card.update!(user: buyer, status: "active", ...)
  listing.mark_as_sold!
end
```

**Impact:**
- Could transfer gift card even if listing was cancelled
- Could transfer gift card that was already sold
- Data inconsistency

**Recommendation:**
```ruby
def complete_sale!
  gift_card = listing.gift_card
  
  # Verify listing is still active
  raise ActiveRecord::RecordInvalid unless listing.active?
  
  # Verify gift card hasn't been transferred
  raise ActiveRecord::RecordInvalid if gift_card.user_id != seller_id
  
  ActiveRecord::Base.transaction do
    gift_card.update!(user: buyer, status: "active", acquired_from: "bought_on_cardly")
    listing.mark_as_sold!
  end
end
```

---

### 5. Missing Strong Parameters in Counter Action
**Severity:** Medium  
**Location:** `app/controllers/transactions_controller.rb:87-96`

**Issue:** Direct access to params without strong parameters.

**Current Code:**
```ruby
def counter
  counter_amount = params[:counter_amount].to_d
  counter_message = params[:counter_message]
  # ...
end
```

**Recommendation:**
```ruby
def counter
  if @transaction.counter!(counter_params[:counter_amount], counter_params[:counter_message])
    # ...
  end
end

private

def counter_params
  params.permit(:counter_amount, :counter_message)
end
```

---

### 6. Missing Stripe Refund in Dispute Resolution
**Severity:** High  
**Location:** `app/models/dispute.rb:183-190`

**Issue:** Dispute resolution marks payment as "refunded" but doesn't actually process Stripe refund.

**Current Code:**
```ruby
def handle_buyer_favor_resolution
  if card_transaction.sale? && card_transaction.payment_completed?
    card_transaction.update!(payment_status: "refunded")
    # No actual Stripe refund processed
    card_transaction.gift_card.update!(user: seller, status: "active")
  end
end
```

**Impact:**
- Buyer doesn't receive actual refund
- Financial loss for buyer
- Legal/compliance issues

**Recommendation:**
```ruby
def handle_buyer_favor_resolution
  return unless card_transaction.sale? && card_transaction.payment_completed?
  
  # Process actual Stripe refund
  begin
    refund = Stripe::Refund.create(
      payment_intent: card_transaction.stripe_payment_intent_id,
      amount: card_transaction.payment_amount_cents,
      reason: "dispute_resolution"
    )
    
    ActiveRecord::Base.transaction do
      card_transaction.update!(
        payment_status: "refunded",
        stripe_refund_id: refund.id
      )
      # Return gift card to seller
      card_transaction.gift_card.update!(user: seller, status: "active")
    end
  rescue Stripe::StripeError => e
    Rails.logger.error("Refund failed for dispute #{id}: #{e.message}")
    # Mark for manual review
    update!(admin_notes: "Refund failed: #{e.message}")
  end
end
```

---

## 🟡 Data Integrity Recommendations

### 7. Add Optimistic Locking
**Severity:** Medium  
**Location:** Multiple models

**Issue:** No optimistic locking on critical models (Transaction, GiftCard, Listing).

**Recommendation:**
Add `lock_version` column to critical models:
```ruby
# Migration
add_column :transactions, :lock_version, :integer, default: 0, null: false
add_column :gift_cards, :lock_version, :integer, default: 0, null: false
add_column :listings, :lock_version, :integer, default: 0, null: false

# Models automatically use optimistic locking with lock_version
```

---

### 8. Webhook Event Idempotency
**Severity:** Medium  
**Location:** `app/controllers/webhooks_controller.rb`

**Issue:** No tracking of processed webhook events to prevent duplicates.

**Recommendation:**
Create a `StripeWebhookEvent` model to track processed events:
```ruby
# Migration
create_table :stripe_webhook_events do |t|
  t.string :stripe_event_id, null: false, unique: true
  t.string :event_type, null: false
  t.boolean :processed, default: false
  t.text :payload
  t.timestamps
end

# In webhook handler
def stripe
  event = Stripe::Webhook.construct_event(...)
  
  # Check if already processed
  webhook_event = StripeWebhookEvent.find_or_create_by(stripe_event_id: event.id) do |we|
    we.event_type = event.type
    we.payload = event.to_json
  end
  
  return render json: { received: true }, status: :ok if webhook_event.processed?
  
  # Process event
  process_webhook_event(event)
  
  webhook_event.update!(processed: true)
end
```

---

### 9. Missing Transaction Validation on Accept
**Severity:** Medium  
**Location:** `app/models/transaction.rb:163`

**Issue:** `accept!` doesn't re-validate that listing is still active.

**Recommendation:**
```ruby
def accept!
  return false unless pending?
  
  # Re-validate listing is active
  unless listing.active?
    errors.add(:listing, "is no longer available")
    return false
  end
  
  with_lock do
    return false unless pending?
    # ...
  end
end
```

---

### 10. Card Activity Balance Calculation Race Condition
**Severity:** Medium  
**Location:** `app/models/card_activity.rb:59-75`

**Issue:** Balance calculation reads current balance without lock, then updates it.

**Current Code:**
```ruby
def calculate_balances
  self.balance_before = gift_card.balance # Read without lock
  # ... calculate balance_after
end
```

**Recommendation:**
```ruby
def calculate_balances
  return unless gift_card
  
  gift_card.with_lock do
    self.balance_before = gift_card.balance
    
    case activity_type
    when "purchase"
      self.balance_after = [balance_before - amount, 0].max
    # ...
    end
  end
end
```

---

## 🟢 Code Quality Issues

### 11. Missing Error Handling in Critical Paths
**Severity:** Low  
**Location:** Multiple files

**Issues:**
- `complete_trade!` doesn't handle errors if buyer card listing cancel fails
- `initiate_seller_payout` doesn't rollback transaction if payout fails
- Card activity balance update could fail silently

**Recommendation:** Add comprehensive error handling and rollback mechanisms.

---

### 12. Missing Background Job Error Handling
**Severity:** Low  
**Location:** `app/jobs/expiration_reminder_job.rb`

**Issue:** No error handling if email delivery fails.

**Recommendation:**
```ruby
def send_30_day_reminders
  GiftCard.needs_30_day_reminder.includes(:user, :brand).find_each do |card|
    begin
      GiftCardMailer.expiration_reminder(card, 30).deliver_later
      card.update!(reminder_sent_at: Time.current)
    rescue => e
      Rails.logger.error("Failed to send reminder for card #{card.id}: #{e.message}")
      # Don't update reminder_sent_at so it can be retried
    end
  end
end
```

---

## 📊 Summary

### Critical Issues (Fix Immediately)
1. ✅ Race condition in transaction acceptance
2. ✅ Missing idempotency in payment completion
3. ✅ Race condition in gift card balance updates
4. ✅ Missing validation in transaction completion
5. ✅ Missing Stripe refund in dispute resolution

### High Priority (Fix Soon)
6. ✅ Missing strong parameters in counter action
7. ✅ Add optimistic locking
8. ✅ Webhook event idempotency

### Medium Priority (Plan for Next Sprint)
9. ✅ Transaction validation on accept
10. ✅ Card activity balance calculation
11. ✅ Error handling improvements
12. ✅ Background job error handling

---

## 🔧 Immediate Action Items

1. **Add database locks** to `accept!`, `accept_counter!`, and `complete_payment!`
2. **Add idempotency checks** in payment completion and webhook handlers
3. **Fix balance update race condition** in CardActivity
4. **Add validation** in transaction completion methods
5. **Implement Stripe refunds** in dispute resolution
6. **Add strong parameters** to counter action
7. **Add optimistic locking** to critical models

---

**Report Generated:** January 23, 2026  
**Priority:** Critical - These issues could lead to financial losses and data corruption
