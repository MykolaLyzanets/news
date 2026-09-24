# frozen_string_literal: true

class SiteSetting < ApplicationRecord
  validate :google_sheets_service_account_json_format

  def self.current
    first_or_create!
  end

  def google_service_account_email
    parsed_google_service_account&.fetch('client_email', nil)
  end

  def parsed_google_service_account
    raw = google_sheets_service_account_json.to_s.strip
    return if raw.blank?

    JSON.parse(raw)
  rescue JSON::ParserError
    nil
  end

  private

  def google_sheets_service_account_json_format
    raw = google_sheets_service_account_json.to_s.strip
    return if raw.blank?

    data = parsed_google_service_account
    unless data.is_a?(Hash)
      errors.add(:google_sheets_service_account_json, 'must be valid JSON')
      return
    end

    missing = %w[type client_email private_key] - data.keys
    return if missing.empty?

    errors.add(:google_sheets_service_account_json, "is missing fields: #{missing.join(', ')}")
  end
end
