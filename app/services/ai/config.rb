# frozen_string_literal: true

module Ai
  class Config
    def self.api_key
      rails_dig(:open_ai, :api_key)
    end

    def self.configured?
      api_key.present?
    end

    def self.rails_dig(*keys)
      Rails.application.credentials.dig(*keys).presence
    rescue StandardError
      nil
    end
  end
end
