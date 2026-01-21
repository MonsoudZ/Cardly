class CreateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :cards do |t|
      t.string :name, null: false
      t.text :description
      t.string :card_type, null: false
      t.string :set_name
      t.string :card_number
      t.string :rarity
      t.string :image_url
      t.decimal :estimated_value, precision: 10, scale: 2

      t.timestamps
    end

    add_index :cards, :card_type
    add_index :cards, :set_name
    add_index :cards, :rarity
    add_index :cards, [:card_type, :set_name, :card_number], unique: true, name: 'index_cards_on_type_set_number'
  end
end
