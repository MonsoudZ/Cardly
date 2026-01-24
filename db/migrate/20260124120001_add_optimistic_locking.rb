class AddOptimisticLocking < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :lock_version, :integer, default: 0, null: false
    add_column :gift_cards, :lock_version, :integer, default: 0, null: false
    add_column :listings, :lock_version, :integer, default: 0, null: false
  end
end
