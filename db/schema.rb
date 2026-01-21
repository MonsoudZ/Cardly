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

ActiveRecord::Schema[8.1].define(version: 2026_01_21_190517) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "cards", force: :cascade do |t|
    t.string "card_number"
    t.string "card_type", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "estimated_value", precision: 10, scale: 2
    t.string "image_url"
    t.string "name", null: false
    t.string "rarity"
    t.string "set_name"
    t.datetime "updated_at", null: false
    t.index ["card_type", "set_name", "card_number"], name: "index_cards_on_type_set_number", unique: true
    t.index ["card_type"], name: "index_cards_on_card_type"
    t.index ["rarity"], name: "index_cards_on_rarity"
    t.index ["set_name"], name: "index_cards_on_set_name"
  end

  create_table "collection_items", force: :cascade do |t|
    t.date "acquired_date"
    t.decimal "acquired_price", precision: 10, scale: 2
    t.decimal "asking_price", precision: 10, scale: 2
    t.bigint "card_id", null: false
    t.bigint "collection_id", null: false
    t.string "condition", default: "good"
    t.datetime "created_at", null: false
    t.boolean "for_sale", default: false, null: false
    t.boolean "for_trade", default: false, null: false
    t.text "notes"
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["card_id"], name: "index_collection_items_on_card_id"
    t.index ["collection_id", "card_id"], name: "index_collection_items_on_collection_id_and_card_id", unique: true
    t.index ["collection_id"], name: "index_collection_items_on_collection_id"
    t.index ["for_sale"], name: "index_collection_items_on_for_sale"
    t.index ["for_trade"], name: "index_collection_items_on_for_trade"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.boolean "public", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_collections_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_collections_on_user_id"
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

  add_foreign_key "collection_items", "cards"
  add_foreign_key "collection_items", "collections"
  add_foreign_key "collections", "users"
end
