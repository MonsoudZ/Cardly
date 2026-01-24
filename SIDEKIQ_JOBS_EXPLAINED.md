# Sidekiq Jobs Explained
**Date:** January 23, 2026  
**Application:** Cardly - Gift Card Marketplace

This document explains what each Sidekiq background job does in the Cardly application.

---

## 📋 Scheduled Jobs (Recurring)

### 1. ExpirationReminderJob
**Schedule:** Runs daily at 9 AM UTC  
**File:** `app/jobs/expiration_reminder_job.rb`

**What it does:**
This job sends email reminders to users about their gift cards that are expiring soon, and marks expired cards.

**Tasks performed:**

1. **30-Day Reminders**
   - Finds gift cards expiring in ~30 days
   - Sends email reminder to card owner
   - Updates `reminder_sent_at` timestamp
   - Purpose: Give users plenty of time to use or sell their cards

2. **7-Day Reminders**
   - Finds gift cards expiring in ~7 days
   - Sends email reminder to card owner
   - Updates `reminder_7_day_sent_at` timestamp
   - Purpose: Urgent reminder before expiration

3. **1-Day Reminders**
   - Finds gift cards expiring tomorrow
   - Sends email reminder to card owner
   - Updates `reminder_1_day_sent_at` timestamp
   - Purpose: Last chance reminder

4. **Mark Expired Cards**
   - Finds gift cards with `expiration_date` in the past
   - Updates card status to "expired"
   - Sends "card expired" email notification
   - Purpose: Keep database accurate and notify users

**Example:**
```
User has a $50 Starbucks card expiring in 25 days
→ Job sends 30-day reminder email
→ User receives: "Your Starbucks card expires in 30 days!"
```

---

### 2. TransactionExpirationJob
**Schedule:** Runs every hour  
**File:** `app/jobs/transaction_expiration_job.rb`

**What it does:**
This job automatically expires old transaction offers that have passed their expiration date.

**Tasks performed:**

1. **Expire Pending Transactions**
   - Finds transactions with status "pending" where `expires_at <= now`
   - Calls `transaction.expire!` method
   - Sends "offer expired" notification email
   - Purpose: Clean up old offers that were never accepted

2. **Expire Countered Transactions**
   - Finds transactions with status "countered" where `expires_at <= now`
   - Calls `transaction.expire!` method
   - Sends "offer expired" notification email
   - Purpose: Clean up counteroffers that were never accepted

**Example:**
```
Buyer makes offer on listing at 2 PM
Offer expires at 48 hours (2 PM + 2 days)
→ If not accepted by 2 PM in 2 days, job expires it
→ Both buyer and seller get "offer expired" email
→ Listing becomes available again for other offers
```

**Why hourly?**
- Offers expire at various times throughout the day
- Hourly check ensures offers expire within 1 hour of their expiration time
- More frequent than daily, less resource-intensive than every minute

---

## 🔄 Background Jobs (Triggered by Events)

These jobs are triggered automatically when certain events happen in the application. They use `deliver_later` which queues them through Sidekiq.

### 3. Email Notifications (via Mailers)

**Transaction Emails** (`TransactionMailer`):
- **New Offer** - When buyer makes an offer on a listing
- **Offer Accepted** - When seller accepts an offer
- **Offer Rejected** - When seller rejects an offer
- **Offer Cancelled** - When buyer cancels their offer
- **Counteroffer** - When seller makes a counteroffer
- **Counter Accepted** - When buyer accepts counteroffer
- **Counter Rejected** - When buyer rejects counteroffer
- **Offer Expired** - When offer expires (also sent by TransactionExpirationJob)
- **Payment Request** - When payment is needed for accepted offer
- **Payment Completed** - When payment is successfully processed
- **Payment Failed** - When payment processing fails

**Gift Card Emails** (`GiftCardMailer`):
- **Expiration Reminder** - Sent by ExpirationReminderJob (30, 7, or 1 day)
- **Card Expired** - Sent when card is marked as expired

**Dispute Emails** (`DisputeMailer`):
- **Dispute Opened** - When user opens a dispute
- **Dispute Status Changed** - When dispute status updates

**Message Emails** (`MessageMailer`):
- **New Message** - When user receives a message in a transaction

**Listing Emails** (`ListingMailer`):
- **Price Drop Notification** - When listing price drops and user is watching it

---

## 🔧 How Sidekiq Works

### Job Queue System
1. **Jobs are queued** when code calls `.deliver_later` or `.perform_later`
2. **Sidekiq worker** processes jobs from the queue
3. **Redis** stores the job queue
4. **Jobs run asynchronously** - don't block the web request

### Example Flow:

**User makes an offer:**
```
1. User clicks "Make Offer" button
2. Controller creates Transaction record
3. Code calls: TransactionMailer.new_offer(self).deliver_later
4. Job is queued in Sidekiq (via Redis)
5. Web request completes immediately (user sees success message)
6. Sidekiq worker picks up job
7. Email is sent in background
```

**Benefits:**
- ✅ Fast web responses (no waiting for email to send)
- ✅ Retry failed jobs automatically
- ✅ Monitor job status
- ✅ Scale workers independently

---

## 📊 Job Monitoring

### View Jobs in Sidekiq Web UI

If Sidekiq Web UI is configured (see `NEXT_STEPS_COMPLETED.md`):

1. Navigate to `/sidekiq` (admin only)
2. View:
   - **Scheduled** - Recurring jobs (ExpirationReminderJob, TransactionExpirationJob)
   - **Queued** - Jobs waiting to be processed
   - **Busy** - Jobs currently running
   - **Retries** - Failed jobs waiting to retry
   - **Dead** - Jobs that failed too many times

### Manual Job Execution

**In Rails console:**
```ruby
# Run expiration reminder job manually
ExpirationReminderJob.perform_now

# Run transaction expiration job manually
TransactionExpirationJob.perform_now

# Check scheduled jobs
Sidekiq::Cron::Job.all
```

---

## ⚙️ Configuration

### Schedule Times

**ExpirationReminderJob:**
- Current: 9 AM UTC daily
- Change in: `config/initializers/sidekiq_cron.rb`
- Example: `'0 9 * * *'` = 9 AM UTC

**TransactionExpirationJob:**
- Current: Every hour at minute 0
- Change in: `config/initializers/sidekiq_cron.rb`
- Example: `'0 * * * *'` = Every hour

### Disable in Development

Add to `.env`:
```bash
SIDEKIQ_CRON_ENABLED=false
```

---

## 🎯 Summary

| Job | When It Runs | What It Does |
|-----|--------------|--------------|
| **ExpirationReminderJob** | Daily at 9 AM UTC | Sends gift card expiration reminders (30, 7, 1 day) and marks expired cards |
| **TransactionExpirationJob** | Every hour | Expires old pending/countered transaction offers |
| **Email Jobs** | On-demand (via `deliver_later`) | Sends notifications for transactions, disputes, messages, etc. |

---

## 🔍 Related Files

- `app/jobs/expiration_reminder_job.rb` - Gift card expiration reminders
- `app/jobs/transaction_expiration_job.rb` - Transaction expiration cleanup
- `config/initializers/sidekiq_cron.rb` - Job scheduling configuration
- `config/initializers/sidekiq.rb` - Sidekiq setup
- `app/mailers/*` - Email templates for notifications

---

**Last Updated:** January 23, 2026
