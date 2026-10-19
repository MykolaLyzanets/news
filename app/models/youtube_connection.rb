# frozen_string_literal: true

class YoutubeConnection < ApplicationRecord
  include TokenEncryptable

  STATUSES = %w[disconnected connected invalid].freeze

  has_many :autoria_youtube_uploads, dependent: :nullify

  validates :status, inclusion: { in: STATUSES }
  validate :google_oauth_credentials_together

  before_validation :normalize_google_client_id
  before_save :clear_google_client_secret_without_id

  scope :active, -> { where(status: 'connected') }

  def connected?
    status == 'connected' && refresh_token.present?
  end

  def display_name
    channel_title.presence || autoria_channel_title.presence || channel_id.presence || "YouTube ##{id}"
  end

  def brands_heading
    brand_labels.to_s.strip.presence || '— вкажіть бренди (як на autoria)'
  end

  def brand_labels_list
    brand_labels.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  def oauth_token_present?
    encrypted_refresh_token.present?
  end

  def token_status_label_ua
    return 'Відключено' if status == 'disconnected'
    return 'Помилка OAuth' if status == 'invalid'
    return 'Немає refresh token' if status == 'connected' && !oauth_token_present?

    if access_token_valid?
      'Токен активний'
    elsif oauth_token_present?
      'Refresh OK (access оновиться при upload)'
    else
      status
    end
  end

  def token_status_badge_class
    case status
    when 'connected'
      oauth_token_present? ? 'admin__badge--live' : 'admin__badge--off'
    when 'invalid'
      'admin__badge--off'
    else
      'admin__badge--draft'
    end
  end

  def refresh_token
    decrypt_secret(encrypted_refresh_token)
  end

  def refresh_token=(value)
    self.encrypted_refresh_token = encrypt_secret(value)
  end

  def access_token
    decrypt_secret(encrypted_access_token)
  end

  def access_token=(value)
    self.encrypted_access_token = encrypt_secret(value)
  end

  def access_token_valid?
    access_token.present? && access_token_expires_at.present? && access_token_expires_at > 2.minutes.from_now
  end

  def google_client_secret
    decrypt_secret(encrypted_google_client_secret)
  end

  def google_client_secret=(value)
    stripped = value.to_s.strip
    return if stripped.blank?

    self.encrypted_google_client_secret = encrypt_secret(stripped)
  end

  def mark_connected!(channel_id:, channel_title:, refresh_token:, access_token:, expires_in:)
    self.channel_id = channel_id
    self.channel_title = channel_title
    self.refresh_token = refresh_token if refresh_token.present?
    self.access_token = access_token
    self.access_token_expires_at = Time.current + expires_in.to_i.seconds
    self.connected_at = Time.current
    self.status = 'connected'
    self.last_error = nil
    save!
  end

  def mark_invalid!(message)
    update!(status: 'invalid', last_error: message.to_s.truncate(2000))
  end

  def disconnect!
    update!(
      status: 'disconnected',
      encrypted_refresh_token: nil,
      encrypted_access_token: nil,
      access_token_expires_at: nil,
      connected_at: nil,
      last_error: nil
    )
  end

  private

  def normalize_google_client_id
    self.google_client_id = google_client_id.to_s.strip.presence
    self.google_redirect_uri = google_redirect_uri.to_s.strip.presence
  end

  def clear_google_client_secret_without_id
    self.encrypted_google_client_secret = nil if google_client_id.blank?
  end

  def google_oauth_credentials_together
    return if google_client_id.blank?
    return if encrypted_google_client_secret.present?

    errors.add(:google_client_secret, :blank)
  end
end
