class CreateGiftCardTags < ActiveRecord::Migration[8.0]
  def change
    create_table :gift_card_tags do |t|
      t.references :gift_card, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :gift_card_tags, [:gift_card_id, :tag_id], unique: true
  end
end
