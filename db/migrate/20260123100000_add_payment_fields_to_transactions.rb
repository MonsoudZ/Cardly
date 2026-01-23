class AddPaymentFieldsToTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :transactions, :payment_status, :string, default: "unpaid"
    add_column :transactions, :stripe_payment_intent_id, :string
    add_column :transactions, :stripe_checkout_session_id, :string
    add_column :transactions, :payment_amount_cents, :integer
    add_column :transactions, :platform_fee_cents, :integer
    add_column :transactions, :seller_payout_cents, :integer
    add_column :transactions, :paid_at, :datetime
    add_column :transactions, :payout_status, :string, default: "pending"
    add_column :transactions, :payout_at, :datetime
    add_column :transactions, :stripe_transfer_id, :string

    add_index :transactions, :stripe_payment_intent_id, unique: true
    add_index :transactions, :stripe_checkout_session_id, unique: true
    add_index :transactions, :payment_status
    add_index :transactions, :payout_status
  end
end
