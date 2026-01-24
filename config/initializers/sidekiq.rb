# Sidekiq configuration
# Make sure Redis is running: redis-server

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

# Optional: Configure Sidekiq web UI for monitoring
# Add to routes.rb: require 'sidekiq/web' and mount Sidekiq::Web => '/sidekiq'
# Protect with authentication in production
