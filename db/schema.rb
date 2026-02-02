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

ActiveRecord::Schema[7.2].define(version: 2026_02_02_131901) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "menu_daily_stats", force: :cascade do |t|
    t.bigint "menu_id", null: false
    t.date "aggregation_date", null: false
    t.integer "total_quantity", default: 0, null: false
    t.integer "total_sales_amount", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aggregation_date"], name: "index_menu_daily_stats_on_aggregation_date"
    t.index ["menu_id", "aggregation_date"], name: "index_menu_daily_stats_on_menu_id_and_aggregation_date", unique: true
    t.index ["menu_id"], name: "index_menu_daily_stats_on_menu_id"
  end

  create_table "menus", force: :cascade do |t|
    t.string "name", null: false
    t.integer "price", null: false
    t.string "image_url"
    t.boolean "is_available", default: true, null: false
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_menus_on_category"
    t.index ["is_available"], name: "index_menus_on_is_available"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.json "menu_snapshot", null: false
    t.integer "quantity", null: false
    t.integer "subtotal", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "table_number"
    t.integer "total_amount", null: false
    t.integer "tax_amount", null: false
    t.string "status", default: "pending", null: false
    t.datetime "ordered_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order_type", default: 0, null: false
    t.index ["order_type"], name: "index_orders_on_order_type"
    t.index ["ordered_at"], name: "index_orders_on_ordered_at"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["table_number"], name: "index_orders_on_table_number"
  end

  add_foreign_key "menu_daily_stats", "menus"
  add_foreign_key "order_items", "orders"
end
