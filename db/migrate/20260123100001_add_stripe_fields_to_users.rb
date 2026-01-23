class AddStripeFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_connect_account_id, :string
    add_column :users, :stripe_connect_onboarded, :boolean, default: false
    add_column :users, :stripe_connect_payouts_enabled, :boolean, default: false

    add_index :users, :stripe_customer_id, unique: true
    add_index :users, :stripe_connect_account_id, unique: true
  end
end
