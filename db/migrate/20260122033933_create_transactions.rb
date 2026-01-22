class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :buyer, null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.references :listing, null: false, foreign_key: true
      t.references :offered_gift_card, foreign_key: { to_table: :gift_cards }
      t.string :transaction_type, null: false, default: "sale"
      t.string :status, null: false, default: "pending"
      t.decimal :amount, precision: 10, scale: 2
      t.text :message

      t.timestamps
    end

    add_index :transactions, :status
    add_index :transactions, :transaction_type
    add_index :transactions, [ :listing_id, :status ]
  end
end
