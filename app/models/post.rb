# frozen_string_literal: true

class Post < ApplicationRecord
  belongs_to :category
  belongs_to :source, optional: true
  belongs_to :event, optional: true
  mount_uploader :image, ImageUploader

  validates :title, presence: true
  validates :url, presence: true, uniqueness: true
  validates :source_url, uniqueness: { allow_nil: true, conditions: -> { where(manual: false) } }
  validates :fingerprint, uniqueness: { allow_nil: true, conditions: -> { where(manual: false) } }
  validates :views, :minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :event_id, uniqueness: true, allow_nil: true

  before_validation :fill_url
  before_validation :fill_empty
  before_validation :fill_originals
  before_validation :normalize_optional_urls
  before_validation :skip_ai_for_manual

  after_commit :enqueue_google_sheets_export, on: %i[create update]

  scope :visible, -> { where(published: true) }
  scope :fresh, -> { where('date >= ?', fresh_since) }
  scope :newest, -> { order(date: :desc) }
  scope :big, -> { where(main: true) }
  scope :urgent, -> { where(breaking: true) }
  scope :popular, -> { order(views: :desc) }
  scope :pending_ai, -> { where(ai_done: false, manual: false) }
  scope :published_today, -> { visible.where(date: Time.zone.now.all_day) }
  scope :quota_counted, -> { where(manual: false) }

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
    text.to_s.split.size >= NewsDesk::Config.min_words
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

  def source_credits
    rows = if event
             event.source_articles.includes(:source).filter_map do |item|
               name = item.source&.name
               next if name.blank?

               { name:, url: item.source_url, date: item.published_at }
             end
           elsif credit_name.present?
             [{ name: credit_name, url: credit_url, date: }]
           else
             []
           end
    rows.uniq { |row| row[:name] }
  end

  def excerpt(words = 36)
    plain = ActionController::Base.helpers.strip_tags(intro.presence || text.to_s).squish
    plain.truncate_words(words, omission: '…')
  end

  def meta_description
    "Read about #{title}. #{category.name}"
  end

  def lead_in
    intro.presence
  end

  def related_topics
    event&.topics.to_a.first(4) || []
  end

  def editorial?
    manual? || event_id.nil?
  end

  def publish_editorial!
    update!(published: true, date: date || Time.current)
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

  def normalize_optional_urls
    self.source_url = source_url.presence
    self.fingerprint = fingerprint.presence
  end

  def skip_ai_for_manual
    self.ai_done = true if manual?
  end

  def enqueue_google_sheets_export
    return unless GoogleSheets::Config.configured?
    return unless published?
    return unless saved_change_to_published?

    GoogleSheets::AppendNewsLinkJob.perform_later(id)
  end
end
