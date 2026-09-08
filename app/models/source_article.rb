# frozen_string_literal: true

class SourceArticle < ApplicationRecord
  STATUSES = %w[pending clustered ignored].freeze

  belongs_to :source
  belongs_to :category
  belongs_to :event, optional: true
  mount_uploader :image, ImageUploader

  validates :title, :source_url, presence: true
  validates :source_url, uniqueness: true
  validates :fingerprint, uniqueness: true, allow_blank: true
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: 'pending', event_id: nil) }
  scope :fresh, -> { where('published_at >= ?', Post.fresh_since) }

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

  def full_story?
    text.to_s.split.size >= NewsDesk::Config.min_words
  end
end
