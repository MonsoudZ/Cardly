# Testing Guide for Recent Fixes
**Date:** January 23, 2026  
**Application:** Cardly - Gift Card Marketplace

This guide provides instructions for testing the pagination and input validation fixes applied to the marketplace.

---

## 1. Testing Pagination

### Prerequisites
- Ensure you have at least 25+ active listings in the database
- Or create test data using Rails console or factories

### Test Steps

#### A. Test Marketplace Index Pagination

1. **Navigate to Marketplace:**
   ```
   http://localhost:3000/marketplace
   ```

2. **Verify Pagination:**
   - Should see maximum 24 listings per page
   - Check for pagination controls at the bottom of the page
   - Verify page numbers or "Next/Previous" links appear

3. **Test Navigation:**
   - Click "Next" or page number "2"
   - Verify URL contains `?page=2`
   - Verify different listings are shown
   - Verify total count badge shows correct number (not just page count)

4. **Test with Filters:**
   - Apply a brand filter
   - Verify pagination still works with filters
   - Verify URL preserves filter parameters: `?brand_id=1&page=2`

5. **Test Edge Cases:**
   - Navigate to last page
   - Verify "Next" button is disabled or hidden
   - Navigate to first page
   - Verify "Previous" button is disabled or hidden

#### B. Test Sales Page Pagination

1. **Navigate to Sales:**
   ```
   http://localhost:3000/marketplace/sales
   ```

2. **Repeat pagination tests from above**

#### C. Test Trades Page Pagination

1. **Navigate to Trades:**
   ```
   http://localhost:3000/marketplace/trades
   ```

2. **Repeat pagination tests from above**

### Expected Results

✅ **Success Criteria:**
- Maximum 24 listings per page
- Pagination controls visible when more than 24 listings exist
- Page navigation works correctly
- Filters are preserved across pages
- Total count shows all listings, not just current page
- No performance degradation with large datasets

❌ **Failure Indicators:**
- All listings load on single page
- No pagination controls visible
- Page navigation doesn't work
- Filters lost when changing pages
- Slow page loads with many listings

### Manual Test Script

```ruby
# In Rails console - Create test data
# Create 30+ listings to test pagination

30.times do |i|
  user = User.first || User.create!(email: "user#{i}@test.com", password: "password123")
  brand = Brand.first || Brand.create!(name: "Test Brand #{i}", category: "retail")
  gift_card = GiftCard.create!(
    user: user,
    brand: brand,
    card_number: "1234567890#{i}",
    balance: 100.00,
    status: "active"
  )
  Listing.create!(
    user: user,
    gift_card: gift_card,
    listing_type: "sale",
    asking_price: 80.00,
    status: "active"
  )
end

# Then test in browser
```

---

## 2. Testing Input Validation

### Test Cases for Marketplace Filters

#### A. Test Brand ID Validation

**Test Case 1: Valid Brand ID**
1. Navigate to marketplace
2. Select a valid brand from dropdown
3. **Expected:** Listings filtered by brand

**Test Case 2: Invalid Brand ID (Non-existent)**
1. Manually edit URL: `?brand_id=99999`
2. **Expected:** No error, but no listings shown (or all listings if validation fails)

**Test Case 3: Invalid Brand ID (Negative)**
1. Manually edit URL: `?brand_id=-1`
2. **Expected:** Filter ignored, all listings shown

**Test Case 4: Invalid Brand ID (Non-numeric)**
1. Manually edit URL: `?brand_id=abc`
2. **Expected:** Filter ignored, all listings shown

#### B. Test Min Discount Validation

**Test Case 1: Valid Discount (0-100)**
1. Navigate to marketplace
2. Select "10%+" from Min Discount dropdown
3. **Expected:** Only listings with >= 10% discount shown

**Test Case 2: Invalid Discount (Negative)**
1. Manually edit URL: `?min_discount=-5`
2. **Expected:** Filter ignored, all listings shown

**Test Case 3: Invalid Discount (Over 100)**
1. Manually edit URL: `?min_discount=150`
2. **Expected:** Filter ignored, all listings shown

**Test Case 4: Invalid Discount (Non-numeric)**
1. Manually edit URL: `?min_discount=abc`
2. **Expected:** Filter ignored, all listings shown

#### C. Test Max Price Validation

**Test Case 1: Valid Price (Positive)**
1. Navigate to marketplace
2. Select "$50" from Max Price dropdown
3. **Expected:** Only listings with price <= $50 shown

**Test Case 2: Invalid Price (Zero)**
1. Manually edit URL: `?max_price=0`
2. **Expected:** Filter ignored, all listings shown

**Test Case 3: Invalid Price (Negative)**
1. Manually edit URL: `?max_price=-10`
2. **Expected:** Filter ignored, all listings shown

**Test Case 4: Invalid Price (Non-numeric)**
1. Manually edit URL: `?max_price=abc`
2. **Expected:** Filter ignored, all listings shown

#### D. Test Min Value Validation

**Test Case 1: Valid Value (Positive)**
1. Manually edit URL: `?min_value=50`
2. **Expected:** Only listings with gift card balance >= $50 shown

**Test Case 2: Invalid Value (Zero or Negative)**
1. Manually edit URL: `?min_value=0` or `?min_value=-10`
2. **Expected:** Filter ignored, all listings shown

#### E. Test Max Value Validation

**Test Case 1: Valid Value (Positive)**
1. Manually edit URL: `?max_value=100`
2. **Expected:** Only listings with gift card balance <= $100 shown

**Test Case 2: Invalid Value (Zero or Negative)**
1. Manually edit URL: `?max_value=0` or `?max_value=-10`
2. **Expected:** Filter ignored, all listings shown

### Automated Test Script

```ruby
# spec/requests/marketplace_validation_spec.rb
require 'rails_helper'

RSpec.describe "Marketplace Filter Validation", type: :request do
  let(:brand) { create(:brand) }
  let(:user) { create(:user) }
  let!(:listing) { create(:listing, user: user, status: "active") }

  describe "brand_id validation" do
    it "accepts valid brand_id" do
      get marketplace_path, params: { brand_id: brand.id }
      expect(response).to have_http_status(:success)
    end

    it "ignores negative brand_id" do
      get marketplace_path, params: { brand_id: -1 }
      expect(response).to have_http_status(:success)
      # Should show all listings, not filtered
    end

    it "ignores non-existent brand_id" do
      get marketplace_path, params: { brand_id: 99999 }
      expect(response).to have_http_status(:success)
      # Should show all listings or empty, not error
    end
  end

  describe "min_discount validation" do
    it "accepts valid discount (0-100)" do
      get marketplace_path, params: { min_discount: 10 }
      expect(response).to have_http_status(:success)
    end

    it "ignores negative discount" do
      get marketplace_path, params: { min_discount: -5 }
      expect(response).to have_http_status(:success)
    end

    it "ignores discount over 100" do
      get marketplace_path, params: { min_discount: 150 }
      expect(response).to have_http_status(:success)
    end
  end

  describe "max_price validation" do
    it "accepts positive price" do
      get marketplace_path, params: { max_price: 50 }
      expect(response).to have_http_status(:success)
    end

    it "ignores zero or negative price" do
      get marketplace_path, params: { max_price: 0 }
      expect(response).to have_http_status(:success)
      
      get marketplace_path, params: { max_price: -10 }
      expect(response).to have_http_status(:success)
    end
  end

  describe "min_value validation" do
    it "accepts positive value" do
      get marketplace_path, params: { min_value: 50 }
      expect(response).to have_http_status(:success)
    end

    it "ignores zero or negative value" do
      get marketplace_path, params: { min_value: 0 }
      expect(response).to have_http_status(:success)
    end
  end

  describe "max_value validation" do
    it "accepts positive value" do
      get marketplace_path, params: { max_value: 100 }
      expect(response).to have_http_status(:success)
    end

    it "ignores zero or negative value" do
      get marketplace_path, params: { max_value: 0 }
      expect(response).to have_http_status(:success)
    end
  end
end
```

---

## 3. Testing Transaction Expiration Job

### Manual Testing

```ruby
# In Rails console

# Create an expired transaction
user1 = User.first
user2 = User.second || User.create!(email: "user2@test.com", password: "password123")
listing = Listing.active.first || Listing.create!(...)
transaction = Transaction.create!(
  buyer: user2,
  seller: user1,
  listing: listing,
  transaction_type: "sale",
  status: "pending",
  amount: 50.00,
  expires_at: 1.hour.ago  # Already expired
)

# Run the job manually
TransactionExpirationJob.perform_now

# Verify transaction is expired
transaction.reload
expect(transaction.status).to eq("expired")
```

### Automated Test

```ruby
# spec/jobs/transaction_expiration_job_spec.rb
require 'rails_helper'

RSpec.describe TransactionExpirationJob, type: :job do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:listing) { create(:listing, user: user1, status: "active") }

  describe "#perform" do
    it "expires pending transactions past expiration date" do
      transaction = create(:transaction,
        buyer: user2,
        seller: user1,
        listing: listing,
        status: "pending",
        expires_at: 1.hour.ago
      )

      expect {
        described_class.perform_now
      }.to change { transaction.reload.status }.from("pending").to("expired")
    end

    it "expires countered transactions past expiration date" do
      transaction = create(:transaction,
        buyer: user2,
        seller: user1,
        listing: listing,
        status: "countered",
        expires_at: 1.hour.ago
      )

      expect {
        described_class.perform_now
      }.to change { transaction.reload.status }.from("countered").to("expired")
    end

    it "does not expire active transactions" do
      transaction = create(:transaction,
        buyer: user2,
        seller: user1,
        listing: listing,
        status: "accepted",
        expires_at: 1.hour.ago
      )

      expect {
        described_class.perform_now
      }.not_to change { transaction.reload.status }
    end
  end
end
```

---

## 4. Testing Scheduled Jobs

### Verify Sidekiq Cron Configuration

1. **Check if sidekiq-cron is loaded:**
   ```ruby
   # In Rails console
   Sidekiq::Cron::Job.all
   ```

2. **Verify scheduled jobs:**
   - Should see "Expiration Reminders - Daily"
   - Should see "Transaction Expiration - Hourly"

3. **Test job execution:**
   ```ruby
   # Manually trigger jobs
   ExpirationReminderJob.perform_now
   TransactionExpirationJob.perform_now
   ```

### Production Setup

1. **Ensure Sidekiq is running:**
   ```bash
   bundle exec sidekiq
   ```

2. **Verify Redis is running:**
   ```bash
   redis-cli ping
   # Should return: PONG
   ```

3. **Monitor Sidekiq Web UI (if configured):**
   - Navigate to `/sidekiq` (if mounted)
   - Check "Cron" tab for scheduled jobs
   - Verify jobs are scheduled and active

---

## 5. Performance Testing

### Test Pagination Performance

```ruby
# In Rails console - Create large dataset
100.times do |i|
  # Create listings...
end

# Measure query time
require 'benchmark'

Benchmark.measure do
  Listing.active.includes(gift_card: :brand).page(1).per(24).to_a
end
```

### Expected Performance

- **With Pagination:** Query should complete in < 100ms for 24 items
- **Without Pagination:** Query could take seconds with 1000+ items

---

## Summary

### Quick Test Checklist

- [ ] Marketplace pagination shows max 24 items per page
- [ ] Pagination controls appear when > 24 listings exist
- [ ] Page navigation works correctly
- [ ] Filters preserved across pages
- [ ] Invalid brand_id is ignored (no error)
- [ ] Invalid min_discount is ignored (no error)
- [ ] Invalid max_price is ignored (no error)
- [ ] Invalid min_value is ignored (no error)
- [ ] Invalid max_value is ignored (no error)
- [ ] Transaction expiration job runs successfully
- [ ] Scheduled jobs are configured in Sidekiq Cron

---

**Last Updated:** January 23, 2026
