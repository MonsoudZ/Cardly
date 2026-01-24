class CreateDisputes < ActiveRecord::Migration[8.0]
  def change
    create_table :disputes do |t|
      t.references :transaction, null: false, foreign_key: true, index: true
      t.references :initiator, null: false, foreign_key: { to_table: :users }
      t.string :reason, null: false
      t.text :description, null: false
      t.string :status, null: false, default: "open"
      t.string :resolution
      t.text :resolution_notes
      t.text :admin_notes
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime :resolved_at
      t.datetime :closed_at

      t.timestamps
    end

    add_index :disputes, :status
    add_index :disputes, :reason
    add_index :disputes, [:transaction_id, :status]
  end
end
