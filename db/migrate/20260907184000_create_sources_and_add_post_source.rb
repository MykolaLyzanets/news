# frozen_string_literal: true

class CreateSourcesAndAddPostSource < ActiveRecord::Migration[7.0]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.references :category, null: false, foreign_key: true
      t.boolean :active, null: false, default: true
      t.integer :sort, null: false, default: 0

      t.timestamps
    end

    add_index :sources, :url, unique: true

    add_reference :posts, :source, foreign_key: true
    add_column :posts, :source_url, :string
    add_column :posts, :ai_done, :boolean, null: false, default: false
    add_index :posts, :source_url, unique: true
  end
end
