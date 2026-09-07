# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :label
      t.text :text
      t.integer :sort, null: false, default: 0

      t.timestamps
    end

    add_index :categories, :url, unique: true
  end
end
