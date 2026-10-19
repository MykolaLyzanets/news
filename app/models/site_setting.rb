# frozen_string_literal: true

class SiteSetting < ApplicationRecord
  include TokenEncryptable

  before_validation :normalize_google_sheets_service_account_json
  before_validation :strip_oauth_fields
  validate :google_sheets_service_account_json_format
  validates :google_redirect_uri, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }, allow_blank: true

  def self.current
    first_or_create!
  end

  def autoria_api_secret
    decrypt_secret(encrypted_autoria_api_secret)
  end

  def autoria_api_secret=(value)
    return if value.blank?

    self.encrypted_autoria_api_secret = encrypt_secret(value.to_s.strip)
  end

  def google_client_secret
    decrypt_secret(encrypted_google_client_secret)
  end

  def google_client_secret=(value)
    return if value.blank?

    self.encrypted_google_client_secret = encrypt_secret(value.to_s.strip)
  end

  def google_oauth_configured?
    google_client_id.present? && google_client_secret.present?
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

  def strip_oauth_fields
    self.google_client_id = google_client_id.to_s.strip.presence
    self.google_redirect_uri = google_redirect_uri.to_s.strip.presence
  end

  def normalize_google_sheets_service_account_json
    raw = google_sheets_service_account_json.to_s.strip
    return if raw.blank?

    data = JSON.parse(raw)
    key = data['private_key']
    if key.is_a?(String) && !key.include?("\n") && key.include?('\\n')
      data['private_key'] = key.gsub('\\n', "\n")
    end
    self.google_sheets_service_account_json = JSON.generate(data)
  rescue JSON::ParserError
    nil
  end

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
