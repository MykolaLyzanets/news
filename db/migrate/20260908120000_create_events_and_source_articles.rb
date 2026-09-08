# frozen_string_literal: true

class CreateEventsAndSourceArticles < ActiveRecord::Migration[7.0]
  def change
    create_table :events do |t|
      t.references :category, null: false, foreign_key: true
      t.string :title, null: false
      t.string :status, null: false, default: 'open'
      t.integer :score, null: false, default: 0
      t.jsonb :score_breakdown, null: false, default: {}
      t.jsonb :facts, null: false, default: {}
      t.jsonb :entities, null: false, default: {}
      t.boolean :breaking, null: false, default: false
      t.integer :source_count, null: false, default: 0
      t.integer :ai_attempts, null: false, default: 0
      t.string :ai_status
      t.text :ai_error
      t.string :quality_status
      t.string :match_key
      t.datetime :first_seen_at
      t.datetime :last_seen_at
      t.datetime :published_at
      t.timestamps
    end
    add_index :events, :status
    add_index :events, :score
    add_index :events, :match_key
    add_index :events, :first_seen_at
    add_index :events, :breaking

    create_table :source_articles do |t|
      t.references :source, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.references :event, foreign_key: true
      t.string :source_url, null: false
      t.string :fingerprint
      t.string :title, null: false
      t.text :intro
      t.text :text
      t.string :original_title
      t.text :original_intro
      t.text :original_text
      t.string :source_image_url
      t.string :image
      t.datetime :published_at
      t.string :status, null: false, default: 'pending'
      t.string :match_key
      t.jsonb :entities, null: false, default: {}
      t.timestamps
    end
    add_index :source_articles, :source_url, unique: true
    add_index :source_articles, :fingerprint, unique: true, where: 'fingerprint IS NOT NULL'
    add_index :source_articles, :status
    add_index :source_articles, :match_key
    add_index :source_articles, :published_at
    add_index :source_articles, %i[event_id status]

    create_table :topics do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :topics, :slug, unique: true
    add_index :topics, :name, unique: true

    create_table :event_topics do |t|
      t.references :event, null: false, foreign_key: true
      t.references :topic, null: false, foreign_key: true
      t.timestamps
    end
    add_index :event_topics, %i[event_id topic_id], unique: true

    add_reference :posts, :event, foreign_key: true, index: false
    add_index :posts, :event_id, unique: true, where: 'event_id IS NOT NULL'
    add_column :posts, :ai_error, :text
    add_column :posts, :quality_status, :string
  end
end
