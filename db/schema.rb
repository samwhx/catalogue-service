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

ActiveRecord::Schema[8.0].define(version: 2025_11_23_042749) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "catalogs", force: :cascade do |t|
    t.string "identifier", null: false
    t.string "name", null: false
    t.date "start_date"
    t.date "end_date"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_catalogs_on_active"
    t.index ["identifier"], name: "index_catalogs_on_identifier", unique: true
  end

  create_table "items", force: :cascade do |t|
    t.string "sku", null: false
    t.bigint "section_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "currency", default: "USD", null: false
    t.integer "display_order", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_items_on_active"
    t.index ["section_id", "display_order"], name: "index_items_on_section_id_and_display_order"
    t.index ["section_id"], name: "index_items_on_section_id"
    t.index ["sku"], name: "index_items_on_sku", unique: true
  end

  create_table "options", force: :cascade do |t|
    t.bigint "item_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "currency", default: "USD", null: false
    t.integer "display_order", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_options_on_active"
    t.index ["item_id", "display_order"], name: "index_options_on_item_id_and_display_order"
    t.index ["item_id"], name: "index_options_on_item_id"
  end

  create_table "sections", force: :cascade do |t|
    t.string "identifier", null: false
    t.bigint "catalog_id", null: false
    t.bigint "parent_id"
    t.string "name", null: false
    t.text "description"
    t.integer "display_order", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_sections_on_active"
    t.index ["catalog_id", "display_order"], name: "index_sections_on_catalog_id_and_display_order"
    t.index ["catalog_id"], name: "index_sections_on_catalog_id"
    t.index ["identifier"], name: "index_sections_on_identifier", unique: true
    t.index ["parent_id"], name: "index_sections_on_parent_id"
  end

  add_foreign_key "items", "sections"
  add_foreign_key "options", "items"
  add_foreign_key "sections", "catalogs"
  add_foreign_key "sections", "sections", column: "parent_id"
end
