class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Listings indexes
    add_index :listings, :status, if_not_exists: true
    add_index :listings, :listing_type, if_not_exists: true
    add_index :listings, [:status, :listing_type], if_not_exists: true
    add_index :listings, [:user_id, :status], if_not_exists: true

    # Transactions indexes
    add_index :transactions, [:buyer_id, :status], if_not_exists: true
    add_index :transactions, [:seller_id, :status], if_not_exists: true
    add_index :transactions, [:listing_id, :status], if_not_exists: true
    add_index :transactions, :transaction_type, if_not_exists: true

    # Gift cards indexes
    add_index :gift_cards, [:user_id, :status], if_not_exists: true
    add_index :gift_cards, :status, if_not_exists: true

    # Messages indexes
    add_index :messages, [:transaction_id, :created_at], if_not_exists: true
    add_index :messages, :read_at, if_not_exists: true

    # Ratings indexes
    add_index :ratings, [:ratee_id, :role], if_not_exists: true
    add_index :ratings, :rater_id, if_not_exists: true

    # Favorites indexes
    add_index :favorites, [:user_id, :listing_id], unique: true, if_not_exists: true

    # Card activities indexes
    add_index :card_activities, [:gift_card_id, :occurred_at], if_not_exists: true

    # Tags indexes
    add_index :tags, [:user_id, :name], if_not_exists: true

    # Brands indexes
    add_index :brands, :category, if_not_exists: true
    add_index :brands, :active, if_not_exists: true
  end
end
