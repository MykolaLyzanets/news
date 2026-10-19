# frozen_string_literal: true

module Autoria
  module ApiSecret
    module_function

    def current
      from_site_settings.presence ||
        ENV['AUTORIA_NEWS_API_SECRET'].presence ||
        Rails.application.credentials.dig(:autoria_news, :api_secret).to_s.presence
    end

    def from_site_settings
      return unless defined?(SiteSetting) && SiteSetting.table_exists?

      SiteSetting.current.autoria_api_secret.presence
    end

    def sign(body)
      secret = current
      raise 'AUTORIA_NEWS_API_SECRET is missing' if secret.blank?

      OpenSSL::HMAC.hexdigest('SHA256', secret, body)
    end

    def verify!(body, signature)
      expected = sign(body)
      raise ActionController::BadRequest, 'invalid signature' unless secure_compare(expected, signature.to_s)
    end

    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      ActiveSupport::SecurityUtils.secure_compare(a, b)
    end
  end
end
