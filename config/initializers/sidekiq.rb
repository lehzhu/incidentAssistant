# config/initializers/sidekiq.rb

# Configure Sidekiq to use database 0 for better isolation
# Note: Sidekiq 7+ removed namespace support, so we use database separation instead
Sidekiq.configure_server do |config|
  config.redis = { 
    url: 'redis://localhost:6379/0'
  }
end

Sidekiq.configure_client do |config|
  config.redis = { 
    url: 'redis://localhost:6379/0'
  }
end

# Optional: Configure job retry settings
Sidekiq.configure_server do |config|
  config.death_handlers << ->(job, ex) do
    Rails.logger.error "Job #{job['jid']} died: #{ex.message}"
  end
end
