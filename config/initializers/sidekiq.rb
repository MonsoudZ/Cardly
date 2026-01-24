# Sidekiq configuration
# Make sure Redis is running: redis-server

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
  
  # Load scheduled jobs from sidekiq-cron
  if defined?(Sidekiq::Cron)
    schedule_file = Rails.root.join("config", "schedule.yml")
    if schedule_file.exist?
      Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

# Optional: Configure Sidekiq web UI for monitoring
# Add to routes.rb: require 'sidekiq/web' and mount Sidekiq::Web => '/sidekiq'
# Protect with authentication in production
