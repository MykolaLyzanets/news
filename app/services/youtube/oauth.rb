# frozen_string_literal: true

require 'httparty'

module Youtube
  class Oauth
    include HTTParty
    base_uri 'https://oauth2.googleapis.com'
    default_timeout 30

    AUTH_URI = 'https://accounts.google.com/o/oauth2/v2/auth'

    def self.authorization_url(state:, credentials:)
      params = {
        client_id: credentials.fetch(:client_id),
        redirect_uri: credentials.fetch(:redirect_uri),
        response_type: 'code',
        scope: Config::SCOPES.join(' '),
        access_type: 'offline',
        include_granted_scopes: 'true',
        prompt: 'select_account consent',
        state: state
      }
      "#{AUTH_URI}?#{URI.encode_www_form(params)}"
    end

    def self.exchange_code!(code, credentials:)
      response = post(
        '/token',
        body: {
          code: code,
          client_id: credentials.fetch(:client_id),
          client_secret: credentials.fetch(:client_secret),
          redirect_uri: credentials.fetch(:redirect_uri),
          grant_type: 'authorization_code'
        }
      )
      parse_token_response!(response)
    end

    def self.refresh_access_token!(refresh_token, credentials:)
      response = post(
        '/token',
        body: {
          client_id: credentials.fetch(:client_id),
          client_secret: credentials.fetch(:client_secret),
          refresh_token: refresh_token,
          grant_type: 'refresh_token'
        }
      )
      parse_token_response!(response)
    end

    def self.parse_token_response!(response)
      body = response.parsed_response
      body = JSON.parse(body) if body.is_a?(String)

      unless response.success?
        message = body.is_a?(Hash) ? (body['error_description'] || body['error'] || response.message) : response.message
        raise AuthError, "Google OAuth token error: #{message}"
      end

      {
        access_token: body['access_token'],
        refresh_token: body['refresh_token'],
        expires_in: body['expires_in'].to_i,
        token_type: body['token_type'],
        scope: body['scope']
      }
    rescue AuthError
      raise
    rescue StandardError => e
      raise AuthError, "Google OAuth request failed: #{e.class} - #{e.message}"
    end
    private_class_method :parse_token_response!
  end
end
