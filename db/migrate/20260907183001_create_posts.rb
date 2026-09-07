# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.references :category, null: false, foreign_key: true
      t.string :url, null: false
      t.string :title, null: false
      t.text :intro
      t.text :text
      t.string :label
      t.string :note
      t.text :quote
      t.string :quote_name
      t.datetime :date
      t.boolean :published, null: false, default: false
      t.boolean :main, null: false, default: false
      t.boolean :breaking, null: false, default: false
      t.integer :views, null: false, default: 0
      t.integer :minutes, null: false, default: 0
      t.boolean :special, null: false, default: false

      t.timestamps
    end

    add_index :posts, :url, unique: true
    add_index :posts, :published
    add_index :posts, :date
  end
end
