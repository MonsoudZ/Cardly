class CreateCollectionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_items do |t|
      t.references :collection, null: false, foreign_key: true
      t.references :card, null: false, foreign_key: true
      t.string :condition, default: 'good'
      t.integer :quantity, default: 1, null: false
      t.decimal :acquired_price, precision: 10, scale: 2
      t.date :acquired_date
      t.boolean :for_trade, default: false, null: false
      t.boolean :for_sale, default: false, null: false
      t.decimal :asking_price, precision: 10, scale: 2
      t.text :notes

      t.timestamps
    end

    add_index :collection_items, :for_trade
    add_index :collection_items, :for_sale
    add_index :collection_items, [:collection_id, :card_id], unique: true
  end
end
