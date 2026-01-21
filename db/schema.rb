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

ActiveRecord::Schema[8.1].define(version: 2026_01_21_215955) do
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
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["brand_id"], name: "index_gift_cards_on_brand_id"
    t.index ["expiration_date"], name: "index_gift_cards_on_expiration_date"
    t.index ["status"], name: "index_gift_cards_on_status"
    t.index ["user_id", "status"], name: "index_gift_cards_on_user_id_and_status"
    t.index ["user_id"], name: "index_gift_cards_on_user_id"
  end

  create_table "listings", force: :cascade do |t|
    t.decimal "asking_price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "discount_percent", precision: 5, scale: 2
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
    t.index ["user_id"], name: "index_listings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "gift_cards", "brands"
  add_foreign_key "gift_cards", "users"
  add_foreign_key "listings", "gift_cards"
  add_foreign_key "listings", "users"
end
