# Active Record Encryption configuration
# For production, set these values via Rails credentials:
#   rails credentials:edit
#   active_record_encryption:
#     primary_key: <32+ char random string>
#     deterministic_key: <32+ char random string>
#     key_derivation_salt: <32+ char random string>

Rails.application.configure do
  config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY") {
    Rails.application.credentials.dig(:active_record_encryption, :primary_key) ||
      (Rails.env.local? ? "S7AUVhND60frj5ukQ1xYs0T7dT0y8qs4" : nil)
  }

  config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY") {
    Rails.application.credentials.dig(:active_record_encryption, :deterministic_key) ||
      (Rails.env.local? ? "lc9tcNxfST42Vge1hfpacHLwUeV3GxDa" : nil)
  }

  config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT") {
    Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt) ||
      (Rails.env.local? ? "xkbqzkZ4ClJZYGxMiuKH5zMNaBXaLlT8" : nil)
  }
end
