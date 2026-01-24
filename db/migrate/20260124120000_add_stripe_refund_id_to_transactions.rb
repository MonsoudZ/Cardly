class AddStripeRefundIdToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :stripe_refund_id, :string
    add_index :transactions, :stripe_refund_id, unique: true
  end
end
