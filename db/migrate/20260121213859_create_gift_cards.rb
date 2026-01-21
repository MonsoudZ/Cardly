class CreateGiftCards < ActiveRecord::Migration[8.1]
  def change
    create_table :gift_cards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :brand, null: false, foreign_key: true
      t.decimal :balance, precision: 10, scale: 2, null: false, default: 0
      t.decimal :original_value, precision: 10, scale: 2, null: false
      t.string :card_number
      t.string :pin
      t.date :expiration_date
      t.string :barcode_data
      t.text :notes
      t.string :status, default: "active", null: false
      t.date :acquired_date
      t.string :acquired_from, default: "purchased"

      t.timestamps
    end

    add_index :gift_cards, :status
    add_index :gift_cards, :expiration_date
    add_index :gift_cards, [ :user_id, :status ]
  end
end
