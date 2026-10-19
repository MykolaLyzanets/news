# frozen_string_literal: true

module Youtube
  class Error < StandardError; end
  class NotConnected < Error; end
  class AuthError < Error; end
  class UploadError < Error; end

  class Config
    SCOPES = [
      'https://www.googleapis.com/auth/youtube.upload',
      'https://www.googleapis.com/auth/youtube.readonly'
    ].freeze

    PRODUCTION_HOST = 'https://lyzfol.com'

    class << self
      def client_id
        from_site_settings(:google_client_id).presence ||
          ENV['GOOGLE_CLIENT_ID'].presence ||
          rails_dig(:google, :client_id)
      end

      def client_secret
        site_settings.google_client_secret.presence ||
          ENV['GOOGLE_CLIENT_SECRET'].presence ||
          rails_dig(:google, :client_secret)
      end

      def redirect_uri
        from_site_settings(:google_redirect_uri).presence ||
          ENV['GOOGLE_REDIRECT_URI'].presence ||
          default_redirect_uri
      end

      def resolve!(connection: nil, client_id: nil, client_secret: nil, redirect_uri: nil)
        id = client_id.to_s.strip.presence || connection&.google_client_id.presence || self.client_id
        secret = client_secret.to_s.strip.presence || connection&.google_client_secret.presence || self.client_secret
        uri = redirect_uri.to_s.strip.presence || connection&.google_redirect_uri.presence || self.redirect_uri

        if id.blank? || secret.blank? || uri.blank?
          raise Error, 'Google OAuth is not configured for news.'
        end

        { client_id: id, client_secret: secret, redirect_uri: uri }
      end

      private

      def default_redirect_uri
        host = Rails.env.production? ? PRODUCTION_HOST : (ENV['APP_HOST'].presence || 'http://localhost:3001')
        host = "https://#{host}" unless host.match?(%r{\Ahttps?://})
        "#{host.chomp('/')}/youtube/oauth/callback"
      end

      def rails_dig(*keys)
        Rails.application.credentials.dig(*keys)
      rescue StandardError
        nil
      end

      def from_site_settings(method)
        site_settings.public_send(method) if site_settings.respond_to?(method)
      end

      def site_settings
        return @site_settings if defined?(@site_settings)

        @site_settings =
          if defined?(SiteSetting) && SiteSetting.table_exists?
            SiteSetting.current
          else
            SiteSetting.new
          end
      end
    end
  end
end
