class AddExpirationReminderFieldsToGiftCards < ActiveRecord::Migration[8.0]
  def change
    add_column :gift_cards, :reminder_sent_at, :datetime
    add_column :gift_cards, :reminder_7_day_sent_at, :datetime
    add_column :gift_cards, :reminder_1_day_sent_at, :datetime

    add_index :gift_cards, :expiration_date
    add_index :gift_cards, [:user_id, :expiration_date]
  end
end
