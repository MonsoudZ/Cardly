# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_24_100001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "brands", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "category", default: "retail"
    t.datetime "created_at", null: false
    t.string "logo_url"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["active"], name: "index_brands_on_active"
    t.index ["category"], name: "index_brands_on_category"
    t.index ["name"], name: "index_brands_on_name", unique: true
  end

  create_table "card_activities", force: :cascade do |t|
    t.string "activity_type", default: "purchase", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.decimal "balance_after", precision: 10, scale: 2
    t.decimal "balance_before", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "gift_card_id", null: false
    t.string "merchant"
    t.datetime "occurred_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_type"], name: "index_card_activities_on_activity_type"
    t.index ["gift_card_id", "occurred_at"], name: "index_card_activities_on_gift_card_id_and_occurred_at"
    t.index ["gift_card_id"], name: "index_card_activities_on_gift_card_id"
    t.index ["occurred_at"], name: "index_card_activities_on_occurred_at"
  end

  create_table "dispute_messages", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "dispute_id", null: false
    t.boolean "is_admin_message", default: false
    t.datetime "read_at"
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["dispute_id", "created_at"], name: "index_dispute_messages_on_dispute_id_and_created_at"
    t.index ["dispute_id", "read_at"], name: "index_dispute_messages_on_dispute_id_and_read_at"
    t.index ["dispute_id"], name: "index_dispute_messages_on_dispute_id"
    t.index ["sender_id"], name: "index_dispute_messages_on_sender_id"
  end

  create_table "disputes", force: :cascade do |t|
    t.text "admin_notes"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.bigint "initiator_id", null: false
    t.string "reason", null: false
    t.string "resolution"
    t.text "resolution_notes"
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.string "status", default: "open", null: false
    t.bigint "transaction_id", null: false
    t.datetime "updated_at", null: false
    t.index ["initiator_id"], name: "index_disputes_on_initiator_id"
    t.index ["reason"], name: "index_disputes_on_reason"
    t.index ["resolved_by_id"], name: "index_disputes_on_resolved_by_id"
    t.index ["reviewed_by_id"], name: "index_disputes_on_reviewed_by_id"
    t.index ["status"], name: "index_disputes_on_status"
    t.index ["transaction_id", "status"], name: "index_disputes_on_transaction_id_and_status"
    t.index ["transaction_id"], name: "index_disputes_on_transaction_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "listing_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["listing_id"], name: "index_favorites_on_listing_id"
    t.index ["user_id", "listing_id"], name: "index_favorites_on_user_id_and_listing_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "gift_card_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "gift_card_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["gift_card_id", "tag_id"], name: "index_gift_card_tags_on_gift_card_id_and_tag_id", unique: true
    t.index ["gift_card_id"], name: "index_gift_card_tags_on_gift_card_id"
    t.index ["tag_id"], name: "index_gift_card_tags_on_tag_id"
  end

  create_table "gift_cards", force: :cascade do |t|
    t.date "acquired_date"
    t.string "acquired_from", default: "purchased"
    t.decimal "balance", precision: 10, scale: 2, default: "0.0", null: false
    t.string "barcode_data"
    t.bigint "brand_id", null: false
    t.string "card_number"
    t.datetime "created_at", null: false
    t.date "expiration_date"
    t.text "notes"
    t.decimal "original_value", precision: 10, scale: 2, null: false
    t.string "pin"
    t.datetime "reminder_1_day_sent_at"
    t.datetime "reminder_7_day_sent_at"
    t.datetime "reminder_sent_at"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["brand_id"], name: "index_gift_cards_on_brand_id"
    t.index ["expiration_date"], name: "index_gift_cards_on_expiration_date"
    t.index ["status"], name: "index_gift_cards_on_status"
    t.index ["user_id", "expiration_date"], name: "index_gift_cards_on_user_id_and_expiration_date"
    t.index ["user_id", "status"], name: "index_gift_cards_on_user_id_and_status"
    t.index ["user_id"], name: "index_gift_cards_on_user_id"
  end

  create_table "listings", force: :cascade do |t|
    t.decimal "asking_price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "discount_percent", precision: 5, scale: 2
    t.integer "favorites_count", default: 0, null: false
    t.bigint "gift_card_id", null: false
    t.string "listing_type", default: "sale", null: false
    t.string "status", default: "active", null: false
    t.text "trade_preferences"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["gift_card_id"], name: "index_listings_on_active_gift_card", unique: true, where: "((status)::text = 'active'::text)"
    t.index ["gift_card_id"], name: "index_listings_on_gift_card_id"
    t.index ["listing_type"], name: "index_listings_on_listing_type"
    t.index ["status", "listing_type"], name: "index_listings_on_status_and_listing_type"
    t.index ["status"], name: "index_listings_on_status"
    t.index ["user_id", "status"], name: "index_listings_on_user_id_and_status"
    t.index ["user_id"], name: "index_listings_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.bigint "sender_id", null: false
    t.bigint "transaction_id", null: false
    t.datetime "updated_at", null: false
    t.index ["read_at"], name: "index_messages_on_read_at"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
    t.index ["transaction_id", "created_at"], name: "index_messages_on_transaction_id_and_created_at"
    t.index ["transaction_id"], name: "index_messages_on_transaction_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "ratee_id", null: false
    t.bigint "rater_id", null: false
    t.string "role", null: false
    t.integer "score", null: false
    t.bigint "transaction_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ratee_id", "role"], name: "index_ratings_on_ratee_id_and_role"
    t.index ["ratee_id"], name: "index_ratings_on_ratee_id"
    t.index ["rater_id"], name: "index_ratings_on_rater_id"
    t.index ["transaction_id", "rater_id"], name: "index_ratings_on_transaction_id_and_rater_id", unique: true
    t.index ["transaction_id"], name: "index_ratings_on_transaction_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "color", default: "#6B7280"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_tags_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2
    t.bigint "buyer_id", null: false
    t.decimal "counter_amount", precision: 10, scale: 2
    t.text "counter_message"
    t.datetime "countered_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.bigint "listing_id", null: false
    t.text "message"
    t.bigint "offered_gift_card_id"
    t.decimal "original_amount", precision: 10, scale: 2
    t.datetime "paid_at"
    t.integer "payment_amount_cents"
    t.string "payment_status", default: "unpaid"
    t.datetime "payout_at"
    t.string "payout_status", default: "pending"
    t.integer "platform_fee_cents"
    t.bigint "seller_id", null: false
    t.integer "seller_payout_cents"
    t.string "status", default: "pending", null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.string "stripe_transfer_id"
    t.string "transaction_type", default: "sale", null: false
    t.datetime "updated_at", null: false
    t.index ["buyer_id", "status"], name: "index_transactions_on_buyer_id_and_status"
    t.index ["buyer_id"], name: "index_transactions_on_buyer_id"
    t.index ["expires_at"], name: "index_transactions_on_expires_at"
    t.index ["listing_id", "status"], name: "index_transactions_on_listing_id_and_status"
    t.index ["listing_id"], name: "index_transactions_on_listing_id"
    t.index ["offered_gift_card_id"], name: "index_transactions_on_offered_gift_card_id"
    t.index ["payment_status"], name: "index_transactions_on_payment_status"
    t.index ["payout_status"], name: "index_transactions_on_payout_status"
    t.index ["seller_id", "status"], name: "index_transactions_on_seller_id_and_status"
    t.index ["seller_id"], name: "index_transactions_on_seller_id"
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["stripe_checkout_session_id"], name: "index_transactions_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_payment_intent_id"], name: "index_transactions_on_stripe_payment_intent_id", unique: true
    t.index ["transaction_type"], name: "index_transactions_on_transaction_type"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "avatar"
    t.integer "completed_purchases_count", default: 0, null: false
    t.integer "completed_sales_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "gift_cards_count", default: 0, null: false
    t.integer "listings_count", default: 0, null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "stripe_connect_account_id"
    t.boolean "stripe_connect_onboarded", default: false
    t.boolean "stripe_connect_payouts_enabled", default: false
    t.string "stripe_customer_id"
    t.datetime "updated_at", null: false
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_connect_account_id"], name: "index_users_on_stripe_connect_account_id", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id", unique: true
  end

  add_foreign_key "card_activities", "gift_cards"
  add_foreign_key "dispute_messages", "disputes"
  add_foreign_key "dispute_messages", "users", column: "sender_id"
  add_foreign_key "disputes", "transactions"
  add_foreign_key "disputes", "users", column: "initiator_id"
  add_foreign_key "disputes", "users", column: "resolved_by_id"
  add_foreign_key "disputes", "users", column: "reviewed_by_id"
  add_foreign_key "favorites", "listings"
  add_foreign_key "favorites", "users"
  add_foreign_key "gift_card_tags", "gift_cards"
  add_foreign_key "gift_card_tags", "tags"
  add_foreign_key "gift_cards", "brands"
  add_foreign_key "gift_cards", "users"
  add_foreign_key "listings", "gift_cards"
  add_foreign_key "listings", "users"
  add_foreign_key "messages", "transactions"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "ratings", "transactions"
  add_foreign_key "ratings", "users", column: "ratee_id"
  add_foreign_key "ratings", "users", column: "rater_id"
  add_foreign_key "tags", "users"
  add_foreign_key "transactions", "gift_cards", column: "offered_gift_card_id"
  add_foreign_key "transactions", "listings"
  add_foreign_key "transactions", "users", column: "buyer_id"
  add_foreign_key "transactions", "users", column: "seller_id"
end
