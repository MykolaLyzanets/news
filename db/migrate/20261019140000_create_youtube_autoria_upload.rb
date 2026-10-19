# frozen_string_literal: true

class CreateYoutubeAutoriaUpload < ActiveRecord::Migration[7.0]
  def change
    create_table :youtube_connections do |t|
      t.string :channel_id
      t.string :channel_title
      t.text :encrypted_refresh_token
      t.text :encrypted_access_token
      t.datetime :access_token_expires_at
      t.datetime :connected_at
      t.string :status, default: 'disconnected', null: false
      t.text :last_error
      t.string :google_client_id
      t.text :encrypted_google_client_secret
      t.string :google_redirect_uri
      t.bigint :autoria_youtube_connection_id
      t.timestamps
    end

    add_index :youtube_connections, :channel_id, unique: true, where: 'channel_id IS NOT NULL'
    add_index :youtube_connections, :autoria_youtube_connection_id,
              unique: true, where: 'autoria_youtube_connection_id IS NOT NULL'

    create_table :autoria_youtube_uploads do |t|
      t.uuid :job_id, null: false
      t.bigint :autoria_vehicle_video_id, null: false
      t.bigint :autoria_youtube_connection_id, null: false
      t.references :youtube_connection, foreign_key: true
      t.string :status, default: 'pending', null: false
      t.string :youtube_video_id
      t.text :error_message
      t.string :video_url, null: false
      t.string :title, null: false
      t.text :description
      t.jsonb :tags, default: [], null: false
      t.string :privacy_status, null: false
      t.string :category_id, null: false
      t.string :callback_url, null: false
      t.integer :poll_attempts, default: 0, null: false
      t.timestamps
    end

    add_index :autoria_youtube_uploads, :job_id, unique: true
    add_index :autoria_youtube_uploads, %i[autoria_vehicle_video_id autoria_youtube_connection_id],
              name: 'index_autoria_yt_uploads_on_video_and_connection'
    add_index :autoria_youtube_uploads, :status
  end
end
