# Sidekiq Cron configuration for scheduled jobs
# This file schedules recurring background jobs
#
# To disable scheduled jobs in development, set SIDEKIQ_CRON_ENABLED=false
# To run jobs manually: TransactionExpirationJob.perform_now or ExpirationReminderJob.perform_now

if defined?(Sidekiq::Cron) && ENV.fetch("SIDEKIQ_CRON_ENABLED", "true") == "true"
  # Schedule Expiration Reminder Job - runs daily at 9 AM UTC
  unless Sidekiq::Cron::Job.find('Expiration Reminders - Daily')
    Sidekiq::Cron::Job.create(
      name: 'Expiration Reminders - Daily',
      cron: '0 9 * * *', # 9 AM daily (UTC)
      class: 'ExpirationReminderJob',
      queue: 'default',
      active_job: true
    )
    Rails.logger.info "Scheduled: Expiration Reminders - Daily (9 AM UTC)"
  end

  # Schedule Transaction Expiration Job - runs every hour
  unless Sidekiq::Cron::Job.find('Transaction Expiration - Hourly')
    Sidekiq::Cron::Job.create(
      name: 'Transaction Expiration - Hourly',
      cron: '0 * * * *', # Every hour at minute 0
      class: 'TransactionExpirationJob',
      queue: 'default',
      active_job: true
    )
    Rails.logger.info "Scheduled: Transaction Expiration - Hourly"
  end
elsif !defined?(Sidekiq::Cron)
  Rails.logger.warn "Sidekiq::Cron not available. Scheduled jobs will not run. Install sidekiq-cron gem."
elsif ENV.fetch("SIDEKIQ_CRON_ENABLED", "true") != "true"
  Rails.logger.info "Sidekiq Cron disabled via SIDEKIQ_CRON_ENABLED=false"
end
