# Next Steps Implementation - Completed
**Date:** January 23, 2026  
**Application:** Cardly - Gift Card Marketplace

This document summarizes the implementation of the next steps from the continued audit fixes.

---

## ✅ Completed Tasks

### 1. Scheduled Job Configuration

#### A. Added sidekiq-cron Gem
**File:** `Gemfile`

**Change:**
```ruby
# Background job processing
gem "sidekiq"
# Job scheduling for Sidekiq
gem "sidekiq-cron"
```

**Action Required:**
```bash
bundle install
```

---

#### B. Created Sidekiq Cron Initializer
**File:** `config/initializers/sidekiq_cron.rb` (new file)

**Features:**
- Schedules `ExpirationReminderJob` to run daily at 9 AM UTC
- Schedules `TransactionExpirationJob` to run every hour
- Includes environment variable to enable/disable: `SIDEKIQ_CRON_ENABLED`
- Prevents duplicate job creation
- Includes logging for debugging

**Scheduled Jobs:**
1. **Expiration Reminders - Daily**
   - Cron: `0 9 * * *` (9 AM UTC daily)
   - Job: `ExpirationReminderJob`
   - Purpose: Send expiration reminders for gift cards

2. **Transaction Expiration - Hourly**
   - Cron: `0 * * * *` (Every hour at minute 0)
   - Job: `TransactionExpirationJob`
   - Purpose: Automatically expire old pending/countered transactions

**Configuration:**
- Can be disabled in development by setting `SIDEKIQ_CRON_ENABLED=false`
- Jobs can be run manually: `TransactionExpirationJob.perform_now`

---

#### C. Updated Sidekiq Configuration
**File:** `config/initializers/sidekiq.rb`

**Change:**
- Added support for loading scheduled jobs from YAML file (optional)
- Maintains backward compatibility

---

### 2. Testing Documentation

#### A. Created Comprehensive Testing Guide
**File:** `TESTING_GUIDE.md` (new file)

**Contents:**
1. **Pagination Testing**
   - Manual test steps for all marketplace pages
   - Edge case testing
   - Performance testing guidelines
   - Test data creation scripts

2. **Input Validation Testing**
   - Test cases for all filter parameters:
     - Brand ID validation
     - Min discount validation
     - Max price validation
     - Min value validation
     - Max value validation
   - Edge cases (negative values, non-numeric, out-of-range)
   - Automated test examples (RSpec)

3. **Transaction Expiration Job Testing**
   - Manual testing in Rails console
   - Automated test examples
   - Verification steps

4. **Scheduled Jobs Testing**
   - How to verify Sidekiq Cron configuration
   - Production setup instructions
   - Monitoring guidelines

5. **Performance Testing**
   - Benchmarking scripts
   - Expected performance metrics

---

## 📋 Setup Instructions

### Step 1: Install Dependencies

```bash
bundle install
```

This will install:
- `sidekiq-cron` - Job scheduling for Sidekiq

---

### Step 2: Start Redis (if not running)

```bash
# Check if Redis is running
redis-cli ping

# If not running, start Redis
redis-server
```

---

### Step 3: Start Sidekiq Worker

```bash
# In development
bundle exec sidekiq

# Or add to Procfile for production
# worker: bundle exec sidekiq
```

---

### Step 4: Verify Scheduled Jobs

```ruby
# In Rails console
Sidekiq::Cron::Job.all
# Should show:
# - "Expiration Reminders - Daily"
# - "Transaction Expiration - Hourly"
```

---

### Step 5: Test Jobs Manually (Optional)

```ruby
# In Rails console
# Test transaction expiration
TransactionExpirationJob.perform_now

# Test expiration reminders
ExpirationReminderJob.perform_now
```

---

## 🔧 Configuration Options

### Disable Scheduled Jobs in Development

Add to `.env` or environment:
```bash
SIDEKIQ_CRON_ENABLED=false
```

### Change Schedule Times

Edit `config/initializers/sidekiq_cron.rb`:

```ruby
# Example: Run expiration reminders at 8 AM local time (adjust UTC offset)
cron: '0 8 * * *'  # 8 AM UTC

# Example: Run transaction expiration every 30 minutes
cron: '*/30 * * * *'
```

### Cron Syntax Reference

```
* * * * *
│ │ │ │ │
│ │ │ │ └─── day of week (0-7, Sunday = 0 or 7)
│ │ │ └───── month (1-12)
│ │ └─────── day of month (1-31)
│ └───────── hour (0-23)
└─────────── minute (0-59)
```

Examples:
- `0 9 * * *` - 9 AM daily
- `0 * * * *` - Every hour
- `*/30 * * * *` - Every 30 minutes
- `0 0 * * 0` - Every Sunday at midnight

---

## 📊 Monitoring

### Sidekiq Web UI (Optional)

To enable Sidekiq Web UI for monitoring:

1. **Add to routes:**
   ```ruby
   # config/routes.rb
   require 'sidekiq/web'
   
   # Protect with authentication in production
   authenticate :user, ->(u) { u.admin? } do
     mount Sidekiq::Web => '/sidekiq'
   end
   ```

2. **Access:**
   - Development: `http://localhost:3000/sidekiq`
   - Production: `https://yourdomain.com/sidekiq` (admin only)

3. **Features:**
   - View scheduled jobs
   - Monitor job execution
   - View job history
   - Retry failed jobs

---

## ✅ Verification Checklist

- [ ] `bundle install` completed successfully
- [ ] Redis is running (`redis-cli ping` returns PONG)
- [ ] Sidekiq worker is running (`bundle exec sidekiq`)
- [ ] Scheduled jobs are visible in Rails console: `Sidekiq::Cron::Job.all`
- [ ] Jobs can be run manually: `TransactionExpirationJob.perform_now`
- [ ] Pagination works on marketplace pages (24 items per page)
- [ ] Input validation rejects invalid filter parameters
- [ ] Testing guide reviewed (`TESTING_GUIDE.md`)

---

## 🚀 Production Deployment

### Environment Variables

```bash
# Required
REDIS_URL=redis://your-redis-host:6379/0

# Optional
SIDEKIQ_CRON_ENABLED=true  # Default: true
SIDEKIQ_CONCURRENCY=5       # Number of concurrent workers
```

### Process Management

**Using systemd (Linux):**
```ini
# /etc/systemd/system/sidekiq.service
[Unit]
Description=Sidekiq Background Worker
After=network.target redis.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/path/to/app
Environment=RAILS_ENV=production
ExecStart=/usr/bin/bundle exec sidekiq
Restart=always

[Install]
WantedBy=multi-user.target
```

**Using Procfile (Heroku/foreman):**
```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq
```

---

## 📝 Notes

1. **Time Zones:** Scheduled jobs use UTC. Adjust cron times for your timezone if needed.

2. **Development:** Consider disabling scheduled jobs in development to avoid unnecessary job execution.

3. **Testing:** Use `TESTING_GUIDE.md` for comprehensive testing instructions.

4. **Monitoring:** Set up Sidekiq Web UI or external monitoring (e.g., Sentry) for production.

5. **Job Failures:** Failed jobs will be retried automatically by Sidekiq. Check Sidekiq dashboard for failures.

---

## 🔗 Related Documentation

- `CONTINUED_FIXES.md` - Original fixes applied
- `TESTING_GUIDE.md` - Comprehensive testing guide
- `AUDIT_CONTINUED.md` - Original audit findings
- Sidekiq Documentation: https://github.com/sidekiq/sidekiq
- Sidekiq Cron Documentation: https://github.com/ondrejbartas/sidekiq-cron

---

**Implementation Completed:** January 23, 2026  
**Status:** ✅ Ready for testing and deployment
