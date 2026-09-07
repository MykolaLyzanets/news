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

ActiveRecord::Schema[7.0].define(version: 2026_09_07_234000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.string "label"
    t.text "text"
    t.integer "sort", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_categories_on_url", unique: true
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "url", null: false
    t.string "title", null: false
    t.text "intro"
    t.text "text"
    t.string "label"
    t.string "note"
    t.text "quote"
    t.string "quote_name"
    t.datetime "date"
    t.boolean "published", default: false, null: false
    t.boolean "main", default: false, null: false
    t.boolean "breaking", default: false, null: false
    t.integer "views", default: 0, null: false
    t.integer "minutes", default: 0, null: false
    t.boolean "special", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "source_id"
    t.string "source_url"
    t.boolean "ai_done", default: false, null: false
    t.string "original_title"
    t.text "original_text"
    t.text "original_intro"
    t.string "fingerprint"
    t.string "source_image_url"
    t.string "image"
    t.index ["category_id"], name: "index_posts_on_category_id"
    t.index ["date"], name: "index_posts_on_date"
    t.index ["fingerprint"], name: "index_posts_on_fingerprint", unique: true, where: "(fingerprint IS NOT NULL)"
    t.index ["published"], name: "index_posts_on_published"
    t.index ["source_id"], name: "index_posts_on_source_id"
    t.index ["source_url"], name: "index_posts_on_source_url", unique: true
    t.index ["url"], name: "index_posts_on_url", unique: true
  end

  create_table "sources", force: :cascade do |t|
    t.string "name", null: false
    t.string "url", null: false
    t.bigint "category_id", null: false
    t.boolean "active", default: true, null: false
    t.integer "sort", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "feed_url", null: false
    t.string "parser_type", default: "rss", null: false
    t.string "language", default: "en", null: false
    t.integer "priority", default: 10, null: false
    t.datetime "last_fetched_at"
    t.datetime "last_success_at"
    t.text "last_error"
    t.string "country"
    t.index ["active"], name: "index_sources_on_active"
    t.index ["category_id"], name: "index_sources_on_category_id"
    t.index ["feed_url"], name: "index_sources_on_feed_url", unique: true
    t.index ["url"], name: "index_sources_on_url"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "posts", "categories"
  add_foreign_key "posts", "sources"
  add_foreign_key "sources", "categories"
end
