# frozen_string_literal: true

module Youtube
  class OauthController < Admin::BaseController
    def connect
      connection = YoutubeConnection.find_by(id: params[:youtube_connection_id])
      credentials = Youtube::Config.resolve!(
        connection: connection,
        client_id: params[:google_client_id].to_s.strip.presence,
        client_secret: params[:google_client_secret].to_s.strip.presence,
        redirect_uri: params[:google_redirect_uri].to_s.strip.presence
      )

      state = SecureRandom.hex(24)
      session[:youtube_oauth_state] = state
      session[:youtube_oauth_connection_id] = connection&.id
      session[:youtube_oauth_client_id] = credentials[:client_id]
      session[:youtube_oauth_client_secret] = credentials[:client_secret]
      session[:youtube_oauth_redirect_uri] = credentials[:redirect_uri]
      session[:youtube_oauth_autoria_connection_id] = params[:autoria_youtube_connection_id].presence
      session[:youtube_oauth_brand_labels] = params[:brand_labels].to_s.strip.presence

      redirect_to Youtube::Oauth.authorization_url(state: state, credentials: credentials), allow_other_host: true
    rescue Youtube::Error => e
      clear_oauth_session!
      redirect_to admin_youtube_connections_path, alert: e.message
    end

    def callback
      expected_state = session[:youtube_oauth_state]
      credentials = callback_credentials
      connection_id = session[:youtube_oauth_connection_id]
      autoria_connection_id = session[:youtube_oauth_autoria_connection_id]
      brand_labels = session[:youtube_oauth_brand_labels]
      clear_oauth_session!

      if params[:state].blank? || params[:state] != expected_state || credentials.blank?
        redirect_to admin_youtube_connections_path, alert: 'Невалідний OAuth state'
        return
      end

      if params[:error].present?
        redirect_to admin_youtube_connections_path, alert: "OAuth відхилено: #{params[:error]}"
        return
      end

      tokens = Youtube::Oauth.exchange_code!(params[:code], credentials: credentials)
      info = channel_info_from_tokens(tokens, credentials)
      connection = YoutubeConnection.find_by(id: connection_id) || YoutubeConnection.find_by(channel_id: info[:channel_id])
      connection ||= YoutubeConnection.new

      refresh = tokens[:refresh_token].presence || connection.refresh_token
      if refresh.blank?
        redirect_to admin_youtube_connections_path, alert: 'Google не повернув refresh_token — спробуйте ще раз з prompt=consent'
        return
      end

      connection.google_client_id = credentials[:client_id]
      connection.google_client_secret = credentials[:client_secret]
      connection.google_redirect_uri = credentials[:redirect_uri]
      connection.autoria_youtube_connection_id = autoria_connection_id if autoria_connection_id.present?
      connection.brand_labels = brand_labels if brand_labels.present?
      connection.mark_connected!(
        channel_id: info[:channel_id],
        channel_title: info[:channel_title],
        refresh_token: refresh,
        access_token: tokens[:access_token],
        expires_in: tokens[:expires_in]
      )

      redirect_to admin_youtube_connections_path, notice: "Підключено: #{connection.channel_title}"
    rescue Youtube::Error, Google::Apis::Error => e
      redirect_to admin_youtube_connections_path, alert: e.message
    end

    private

    def callback_credentials
      client_id = session[:youtube_oauth_client_id]
      client_secret = session[:youtube_oauth_client_secret]
      redirect_uri = session[:youtube_oauth_redirect_uri]
      return if client_id.blank? || client_secret.blank?

      Youtube::Config.resolve!(client_id: client_id, client_secret: client_secret, redirect_uri: redirect_uri)
    rescue Youtube::Error
      nil
    end

    def clear_oauth_session!
      session.delete(:youtube_oauth_state)
      session.delete(:youtube_oauth_connection_id)
      session.delete(:youtube_oauth_client_id)
      session.delete(:youtube_oauth_client_secret)
      session.delete(:youtube_oauth_redirect_uri)
      session.delete(:youtube_oauth_autoria_connection_id)
      session.delete(:youtube_oauth_brand_labels)
    end

    def channel_info_from_tokens(tokens, credentials)
      pending = YoutubeConnection.new(status: 'connected')
      pending.google_client_id = credentials[:client_id]
      pending.google_client_secret = credentials[:client_secret]
      pending.google_redirect_uri = credentials[:redirect_uri]
      pending.refresh_token = tokens[:refresh_token] if tokens[:refresh_token].present?
      pending.access_token = tokens[:access_token]
      pending.access_token_expires_at = Time.current + tokens[:expires_in].to_i.seconds
      Youtube::Client.new(connection: pending).channel_info
    end
  end
end
