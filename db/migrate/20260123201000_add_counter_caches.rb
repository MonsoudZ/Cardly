class AddCounterCaches < ActiveRecord::Migration[8.0]
  def change
    # Add counter cache for listings on users
    add_column :users, :listings_count, :integer, default: 0, null: false
    add_column :users, :completed_sales_count, :integer, default: 0, null: false
    add_column :users, :completed_purchases_count, :integer, default: 0, null: false

    # Add counter cache for gift_cards on users
    add_column :users, :gift_cards_count, :integer, default: 0, null: false

    # Add counter cache for favorites on listings
    add_column :listings, :favorites_count, :integer, default: 0, null: false

    # Populate counters
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE users SET listings_count = (
            SELECT COUNT(*) FROM listings WHERE listings.user_id = users.id
          );
        SQL

        execute <<-SQL
          UPDATE users SET gift_cards_count = (
            SELECT COUNT(*) FROM gift_cards WHERE gift_cards.user_id = users.id
          );
        SQL

        execute <<-SQL
          UPDATE listings SET favorites_count = (
            SELECT COUNT(*) FROM favorites WHERE favorites.listing_id = listings.id
          );
        SQL
      end
    end
  end
end
