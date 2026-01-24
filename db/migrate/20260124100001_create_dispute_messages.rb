class CreateDisputeMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :dispute_messages do |t|
      t.references :dispute, null: false, foreign_key: true, index: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :content, null: false
      t.datetime :read_at
      t.boolean :is_admin_message, default: false

      t.timestamps
    end

    add_index :dispute_messages, [:dispute_id, :created_at]
    add_index :dispute_messages, [:dispute_id, :read_at]
  end
end
