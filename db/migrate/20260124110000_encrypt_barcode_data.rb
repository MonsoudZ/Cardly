class EncryptBarcodeData < ActiveRecord::Migration[8.1]
  def up
    # Re-save through encrypted attribute so plaintext rows are encrypted at rest.
    GiftCard.reset_column_information
    GiftCard.find_each do |gift_card|
      next if gift_card.barcode_data.blank?

      gift_card.barcode_data = gift_card.barcode_data
      gift_card.save!(validate: false, touch: false)
    end
  end

  def down
    # Persist decrypted values back to plaintext column for rollback.
    GiftCard.find_each do |gift_card|
      GiftCard.where(id: gift_card.id).update_all(barcode_data: gift_card.barcode_data)
    end
  end
end
