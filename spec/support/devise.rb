RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller

  # Ensure Devise mappings are loaded before running request specs
  # This fixes "Could not find a valid mapping" errors in Rails 8.x
  config.before(:each, type: :request) do
    Rails.application.reload_routes! unless Devise.mappings[:user]
  end
end
