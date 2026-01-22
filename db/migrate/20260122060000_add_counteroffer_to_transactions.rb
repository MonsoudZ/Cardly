class AddCounterofferToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :counter_amount, :decimal, precision: 10, scale: 2
    add_column :transactions, :counter_message, :text
    add_column :transactions, :countered_at, :datetime
    add_column :transactions, :expires_at, :datetime
    add_column :transactions, :original_amount, :decimal, precision: 10, scale: 2

    add_index :transactions, :expires_at
  end
end
