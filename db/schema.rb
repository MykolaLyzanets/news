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

ActiveRecord::Schema[7.0].define(version: 2026_09_08_120000) do
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

  create_table "event_topics", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "topic_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "topic_id"], name: "index_event_topics_on_event_id_and_topic_id", unique: true
    t.index ["event_id"], name: "index_event_topics_on_event_id"
    t.index ["topic_id"], name: "index_event_topics_on_topic_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.string "title", null: false
    t.string "status", default: "open", null: false
    t.integer "score", default: 0, null: false
    t.jsonb "score_breakdown", default: {}, null: false
    t.jsonb "facts", default: {}, null: false
    t.jsonb "entities", default: {}, null: false
    t.boolean "breaking", default: false, null: false
    t.integer "source_count", default: 0, null: false
    t.integer "ai_attempts", default: 0, null: false
    t.string "ai_status"
    t.text "ai_error"
    t.string "quality_status"
    t.string "match_key"
    t.datetime "first_seen_at"
    t.datetime "last_seen_at"
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["breaking"], name: "index_events_on_breaking"
    t.index ["category_id"], name: "index_events_on_category_id"
    t.index ["first_seen_at"], name: "index_events_on_first_seen_at"
    t.index ["match_key"], name: "index_events_on_match_key"
    t.index ["score"], name: "index_events_on_score"
    t.index ["status"], name: "index_events_on_status"
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
    t.bigint "event_id"
    t.text "ai_error"
    t.string "quality_status"
    t.index ["category_id"], name: "index_posts_on_category_id"
    t.index ["date"], name: "index_posts_on_date"
    t.index ["event_id"], name: "index_posts_on_event_id", unique: true, where: "(event_id IS NOT NULL)"
    t.index ["fingerprint"], name: "index_posts_on_fingerprint", unique: true, where: "(fingerprint IS NOT NULL)"
    t.index ["published"], name: "index_posts_on_published"
    t.index ["source_id"], name: "index_posts_on_source_id"
    t.index ["source_url"], name: "index_posts_on_source_url", unique: true
    t.index ["url"], name: "index_posts_on_url", unique: true
  end

  create_table "source_articles", force: :cascade do |t|
    t.bigint "source_id", null: false
    t.bigint "category_id", null: false
    t.bigint "event_id"
    t.string "source_url", null: false
    t.string "fingerprint"
    t.string "title", null: false
    t.text "intro"
    t.text "text"
    t.string "original_title"
    t.text "original_intro"
    t.text "original_text"
    t.string "source_image_url"
    t.string "image"
    t.datetime "published_at"
    t.string "status", default: "pending", null: false
    t.string "match_key"
    t.jsonb "entities", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_source_articles_on_category_id"
    t.index ["event_id", "status"], name: "index_source_articles_on_event_id_and_status"
    t.index ["event_id"], name: "index_source_articles_on_event_id"
    t.index ["fingerprint"], name: "index_source_articles_on_fingerprint", unique: true, where: "(fingerprint IS NOT NULL)"
    t.index ["match_key"], name: "index_source_articles_on_match_key"
    t.index ["published_at"], name: "index_source_articles_on_published_at"
    t.index ["source_id"], name: "index_source_articles_on_source_id"
    t.index ["source_url"], name: "index_source_articles_on_source_url", unique: true
    t.index ["status"], name: "index_source_articles_on_status"
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

  create_table "topics", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_topics_on_name", unique: true
    t.index ["slug"], name: "index_topics_on_slug", unique: true
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
  add_foreign_key "event_topics", "events"
  add_foreign_key "event_topics", "topics"
  add_foreign_key "events", "categories"
  add_foreign_key "posts", "categories"
  add_foreign_key "posts", "events"
  add_foreign_key "posts", "sources"
  add_foreign_key "source_articles", "categories"
  add_foreign_key "source_articles", "events"
  add_foreign_key "source_articles", "sources"
  add_foreign_key "sources", "categories"
end
