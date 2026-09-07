# frozen_string_literal: true

class SwitchPostsToCarrierwave < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :image, :string
    rename_column :posts, :image_url, :source_image_url
  end
end
