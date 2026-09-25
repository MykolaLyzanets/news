# frozen_string_literal: true

class AddManualToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :manual, :boolean, null: false, default: false
    add_index :posts, :manual
  end
end
