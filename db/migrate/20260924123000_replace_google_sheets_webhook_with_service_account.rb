# frozen_string_literal: true

class ReplaceGoogleSheetsWebhookWithServiceAccount < ActiveRecord::Migration[7.0]
  def change
    remove_column :site_settings, :google_sheets_webhook_url, :string
    add_column :site_settings, :google_sheets_service_account_json, :text
  end
end
