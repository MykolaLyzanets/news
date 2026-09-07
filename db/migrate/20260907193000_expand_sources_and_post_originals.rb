# frozen_string_literal: true

class ExpandSourcesAndPostOriginals < ActiveRecord::Migration[7.0]
  def change
    change_table :sources, bulk: true do |t|
      t.string :feed_url
      t.string :parser_type, null: false, default: 'rss'
      t.string :language, null: false, default: 'en'
      t.integer :priority, null: false, default: 10
      t.datetime :last_fetched_at
      t.datetime :last_success_at
      t.text :last_error
    end

    reversible do |dir|
      dir.up do
        execute 'UPDATE sources SET feed_url = url, priority = "sort"'
        change_column_null :sources, :feed_url, false
      end
    end

    remove_index :sources, :url
    add_index :sources, :url
    add_index :sources, :feed_url, unique: true
    add_index :sources, :active

    add_column :posts, :original_title, :string
    add_column :posts, :original_text, :text
    add_column :posts, :original_intro, :text
    add_column :posts, :fingerprint, :string

    reversible do |dir|
      dir.up do
        execute 'UPDATE posts SET original_title = title, original_text = text, original_intro = intro'
      end
    end

    add_index :posts, :fingerprint, unique: true, where: 'fingerprint IS NOT NULL'
  end
end
