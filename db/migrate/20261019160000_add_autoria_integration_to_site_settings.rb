# frozen_string_literal: true

class AddAutoriaIntegrationToSiteSettings < ActiveRecord::Migration[7.0]
  def change
    change_table :site_settings, bulk: true do |t|
      t.text :encrypted_autoria_api_secret
      t.string :google_client_id
      t.text :encrypted_google_client_secret
      t.string :google_redirect_uri
    end
  end
end
