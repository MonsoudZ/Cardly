class EncryptGiftCardSensitiveFields < ActiveRecord::Migration[8.1]
  def up
    # Encrypt existing plaintext data
    # This reads raw values and re-saves them through Active Record encryption
    GiftCard.find_each do |gift_card|
      # Read raw unencrypted values directly from database
      raw_values = GiftCard.connection.select_one(
        "SELECT card_number, pin FROM gift_cards WHERE id = #{gift_card.id}"
      )

      # Skip if already encrypted (starts with encryption marker) or nil
      next if raw_values["card_number"].nil? && raw_values["pin"].nil?
      next if raw_values["card_number"]&.start_with?("{")

      # Re-assign to trigger encryption on save
      gift_card.update_columns(
        card_number: gift_card.class.encrypt(:card_number, raw_values["card_number"]),
        pin: gift_card.class.encrypt(:pin, raw_values["pin"])
      )
    end
  end

  def down
    # Decrypt data back to plaintext (for rollback)
    GiftCard.find_each do |gift_card|
      gift_card.update_columns(
        card_number: gift_card.card_number,
        pin: gift_card.pin
      )
    end
  end
end
