class EncryptBarcodeData < ActiveRecord::Migration[8.1]
  def up
    # Encrypt existing plaintext barcode_data
    # This reads raw values and re-saves them through Active Record encryption
    GiftCard.find_each do |gift_card|
      # Read raw unencrypted value directly from database
      raw_value = GiftCard.connection.select_one(
        "SELECT barcode_data FROM gift_cards WHERE id = ?", gift_card.id
      )&.dig("barcode_data")

      # Skip if already encrypted (starts with encryption marker) or nil
      next if raw_value.nil?
      next if raw_value.start_with?("{")

      # Re-assign to trigger encryption on save
      gift_card.update_columns(
        barcode_data: gift_card.class.encrypt(:barcode_data, raw_value)
      )
    end
  end

  def down
    # Decrypt data back to plaintext (for rollback)
    GiftCard.find_each do |gift_card|
      gift_card.update_columns(
        barcode_data: gift_card.barcode_data
      )
    end
  end
end
