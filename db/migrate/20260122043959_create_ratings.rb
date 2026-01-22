class CreateRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :ratings do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :rater, null: false, foreign_key: { to_table: :users }
      t.references :ratee, null: false, foreign_key: { to_table: :users }
      t.integer :score, null: false
      t.text :comment
      t.string :role, null: false # 'buyer' or 'seller' - who is leaving the rating

      t.timestamps
    end

    # Ensure each user can only rate once per transaction
    add_index :ratings, [ :transaction_id, :rater_id ], unique: true
  end
end
