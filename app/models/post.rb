# frozen_string_literal: true

class Post < ApplicationRecord
  MIN_WORDS = 80

  belongs_to :category
  belongs_to :source, optional: true
  mount_uploader :image, ImageUploader

  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :source_url, uniqueness: true, allow_blank: true
  validates :fingerprint, uniqueness: true, allow_blank: true
  validates :views, :minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :fill_url
  before_validation :fill_empty
  before_validation :fill_originals

  scope :visible, -> { where(published: true) }
  scope :fresh, -> { where('date >= ?', fresh_since) }
  scope :newest, -> { order(date: :desc) }
  scope :big, -> { where(main: true) }
  scope :urgent, -> { where(breaking: true) }
  scope :popular, -> { order(views: :desc) }
  scope :pending_ai, -> { where(ai_done: false) }

  def self.fresh_since
    Time.zone.now.beginning_of_day - 1.day
  end

  def self.fresh?(time)
    time.blank? || time >= fresh_since
  end

  def to_param
    url
  end

  def source_title
    original_title.presence || title
  end

  def source_text
    original_text.presence || text
  end

  def full_story?
    text.to_s.split.size >= MIN_WORDS
  end

  def photo?
    real_image? || NewsSources::Image.usable?(source_image_url)
  end

  def real_image?
    return false if image.blank?

    path = image.path
    path.present? && File.exist?(path) && File.size(path) >= NewsSources::Image::MIN_BYTES
  rescue StandardError
    false
  end

  def credit_name
    return source.name if source&.name.present?

    URI.parse(source_url.to_s).host&.delete_prefix('www.')
  rescue URI::InvalidURIError
    nil
  end

  def credit_url
    source_url.presence || source&.url
  end

  def excerpt(words = 36)
    (text.presence || intro).to_s.squish.truncate_words(words, omission: '…')
  end

  def lead_in
    body = text.to_s.squish
    return if body.blank?

    sentences = body.split(/(?<=[.!?])\s+/)
    return if sentences.size <= 2

    sentences.first(2).join(' ')
  end

  private

  def fill_url
    return if url.present?

    base = title.to_s.parameterize.presence || "post-#{SecureRandom.hex(4)}"
    candidate = base
    index = 2
    while self.class.exists?(url: candidate)
      candidate = "#{base}-#{index}"
      index += 1
    end
    self.url = candidate
  end

  def fill_empty
    self.date ||= Time.current
    self.views ||= 0
    self.minutes ||= 0
  end

  def fill_originals
    self.original_title = title if original_title.blank?
    self.original_text = text if original_text.blank?
    self.original_intro = intro if original_intro.blank?
  end
end
