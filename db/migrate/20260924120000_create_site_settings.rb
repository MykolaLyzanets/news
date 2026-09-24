# frozen_string_literal: true

class CreateSiteSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :site_settings do |t|
      t.string :google_sheets_webhook_url
      t.timestamps
    end
  end
end
