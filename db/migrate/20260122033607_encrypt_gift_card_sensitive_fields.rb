class EncryptGiftCardSensitiveFields < ActiveRecord::Migration[8.1]
  def up
    # Re-save through encrypted attributes so plaintext rows are encrypted at rest.
    GiftCard.reset_column_information
    GiftCard.find_each do |gift_card|
      next if gift_card.card_number.blank? && gift_card.pin.blank?

      gift_card.card_number = gift_card.card_number
      gift_card.pin = gift_card.pin
      gift_card.save!(validate: false, touch: false)
    end
  end

  def down
    # Persist decrypted values back to plaintext columns for rollback.
    GiftCard.find_each do |gift_card|
      GiftCard.where(id: gift_card.id).update_all(
        card_number: gift_card.card_number,
        pin: gift_card.pin
      )
    end
  end
end
