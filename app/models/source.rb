# frozen_string_literal: true

class Source < ApplicationRecord
  PARSER_TYPES = %w[rss atom html api].freeze
  FETCHABLE_TYPES = %w[rss atom].freeze

  belongs_to :category
  has_many :posts, dependent: :nullify

  validates :name, :url, :feed_url, presence: true
  validates :feed_url, uniqueness: true
  validates :parser_type, inclusion: { in: PARSER_TYPES }
  validates :language, presence: true
  validates :priority, numericality: { only_integer: true }
  validate :feed_url_must_be_http

  before_validation :fill_url

  scope :ordered, -> { order(:priority, :name) }
  scope :active, -> { where(active: true) }

  def fetchable?
    FETCHABLE_TYPES.include?(parser_type)
  end

  def mark_fetched!
    update_column(:last_fetched_at, Time.current)
  end

  def mark_success!
    update_columns(last_success_at: Time.current, last_error: nil, last_fetched_at: Time.current)
  end

  def mark_error!(message)
    update_columns(last_error: message.to_s.truncate(1000), last_fetched_at: Time.current)
  end

  private

  def fill_url
    self.url = feed_url if url.blank?
  end

  def feed_url_must_be_http
    uri = URI.parse(feed_url.to_s)
    return if uri.is_a?(URI::HTTP) && uri.host.present?

    errors.add(:feed_url, 'must be a valid http or https URL')
  rescue URI::InvalidURIError
    errors.add(:feed_url, 'must be a valid http or https URL')
  end
end
