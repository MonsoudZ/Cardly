class CreateCardActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :card_activities do |t|
      t.references :gift_card, null: false, foreign_key: true
      t.string :activity_type, null: false, default: "purchase"
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.decimal :balance_before, precision: 10, scale: 2
      t.decimal :balance_after, precision: 10, scale: 2
      t.string :merchant
      t.text :description
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :card_activities, :activity_type
    add_index :card_activities, :occurred_at
    add_index :card_activities, [:gift_card_id, :occurred_at]
  end
end
