# frozen_string_literal: true

class AddBrandLabelsToYoutubeConnections < ActiveRecord::Migration[7.0]
  def change
    change_table :youtube_connections, bulk: true do |t|
      t.string :brand_labels
      t.string :autoria_channel_title
    end
  end
end
