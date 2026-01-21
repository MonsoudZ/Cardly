class CreateListings < ActiveRecord::Migration[8.1]
  def change
    create_table :listings do |t|
      t.references :gift_card, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :listing_type, null: false, default: "sale"
      t.decimal :asking_price, precision: 10, scale: 2
      t.decimal :discount_percent, precision: 5, scale: 2
      t.text :trade_preferences
      t.string :status, default: "active", null: false

      t.timestamps
    end

    add_index :listings, :listing_type
    add_index :listings, :status
    add_index :listings, [ :status, :listing_type ]
    add_index :listings, :gift_card_id, unique: true, where: "status = 'active'", name: "index_listings_on_active_gift_card"
  end
end
