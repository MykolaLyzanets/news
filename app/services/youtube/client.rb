# frozen_string_literal: true

require 'google/apis/youtube_v3'
require 'signet/oauth_2/client'

module Youtube
  class Client
    OPEN_TIMEOUT_SEC = 30
    SEND_TIMEOUT_SEC = 300
    READ_TIMEOUT_SEC = 120

    def initialize(connection:)
      @connection = connection
      return if @connection&.connected?
      return if @connection&.access_token.present? && @connection.access_token_valid?

      raise NotConnected, 'YouTube account is not connected.'
    end

    def service
      @service ||= begin
        ensure_fresh_token!
        youtube = Google::Apis::YoutubeV3::YouTubeService.new
        youtube.client_options.open_timeout_sec = OPEN_TIMEOUT_SEC
        youtube.client_options.send_timeout_sec = SEND_TIMEOUT_SEC
        youtube.client_options.read_timeout_sec = READ_TIMEOUT_SEC
        youtube.authorization = signet_client
        youtube
      end
    end

    def channel_info
      response = service.list_channels('snippet', mine: true, max_results: 1)
      item = response.items&.first
      raise AuthError, 'Unable to read YouTube channel.' if item.blank?

      {
        channel_id: item.id,
        channel_title: item.snippet&.title
      }
    rescue Google::Apis::AuthorizationError => e
      mark_invalid!(e)
      raise AuthError, 'YouTube authorization was revoked. Please reconnect.'
    rescue Google::Apis::ClientError => e
      raise Error, humanize_client_error(e)
    end

    def video_processing_status(youtube_video_id)
      response = service.list_videos('status,processingDetails', id: youtube_video_id)
      item = response.items&.first
      return not_found_status if item.blank?

      status_hash_from_item(item)
    end

    def delete_video!(youtube_video_id)
      id = youtube_video_id.to_s.strip
      raise Error, I18n.t('youtube.errors.video_not_found') if id.blank?

      service.delete_video(id)
      true
    rescue Google::Apis::AuthorizationError => e
      mark_invalid!(e)
      raise AuthError, I18n.t('youtube.errors.auth')
    rescue Google::Apis::ClientError => e
      return true if video_already_gone?(e)
      raise Error, I18n.t('youtube.errors.delete_scope') if insufficient_scopes?(e)

      raise Error, humanize_client_error(e)
    rescue Google::Apis::ServerError, Google::Apis::TransmissionError => e
      raise Error, humanize_client_error(e)
    end

    def ensure_fresh_token!
      return if @connection.access_token_valid?

      tokens = Oauth.refresh_access_token!(@connection.refresh_token, credentials: oauth_credentials)
      @connection.access_token = tokens[:access_token]
      @connection.access_token_expires_at = Time.current + tokens[:expires_in].seconds
      @connection.save! if @connection.persisted?
      @service = nil
    rescue AuthError => e
      mark_invalid!(e)
      raise
    end

    def access_token
      ensure_fresh_token!
      @connection.access_token
    end

    private

    def signet_client
      Signet::OAuth2::Client.new(
        access_token: @connection.access_token,
        refresh_token: @connection.refresh_token,
        token_credential_uri: 'https://oauth2.googleapis.com/token',
        client_id: oauth_credentials[:client_id],
        client_secret: oauth_credentials[:client_secret]
      )
    end

    def oauth_credentials
      @oauth_credentials ||= Config.resolve!(connection: @connection)
    end

    def mark_invalid!(error)
      return unless @connection&.persisted?

      @connection.mark_invalid!(error.message)
    end

    def status_hash_from_item(item)
      details = item.processing_details
      {
        upload_status: item.status&.upload_status,
        privacy_status: item.status&.privacy_status,
        processing_status: details&.processing_status,
        failure: details&.processing_failure_reason,
        processing_details_present: !details.nil?
      }
    end

    def not_found_status
      {
        upload_status: nil,
        privacy_status: nil,
        processing_status: nil,
        failure: Youtube::PublishDecision::NOT_FOUND,
        processing_details_present: false
      }
    end

    def video_already_gone?(error)
      code = error.try(:status_code).to_i
      return true if code == 404

      message = error.message.to_s
      message.match?(/videoNotFound|notFound|\b404\b/i)
    end

    def insufficient_scopes?(error)
      message = error.message.to_s
      code = error.try(:status_code).to_i
      code == 403 && message.match?(/insufficient.*scope|PERMISSION_DENIED|accessNotConfigured/i)
    end

    def humanize_client_error(error)
      message = error.message.to_s
      if message.match?(/YouTube Data API v3 has not been used|it is disabled/i)
        I18n.t('youtube.oauth.api_disabled')
      else
        I18n.t('youtube.oauth.api_error', error: message.truncate(240))
      end
    end
  end
end
