# frozen_string_literal: true

class AutoriaYoutubeUpload < ApplicationRecord
  STATUSES = %w[pending downloading uploading processing published failed].freeze
  IN_PROGRESS_STATUSES = %w[pending downloading uploading processing].freeze

  belongs_to :youtube_connection, optional: true

  validates :job_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :video_url, :title, :privacy_status, :category_id, :callback_url, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :in_progress, -> { where(status: IN_PROGRESS_STATUSES) }
  scope :finished, -> { where(status: %w[published failed]) }

  def mark!(status, **attrs)
    update!(attrs.merge(status: status))
  end

  def in_progress?
    IN_PROGRESS_STATUSES.include?(status)
  end

  def finished?
    %w[published failed].include?(status)
  end

  def channel_label
    connection = youtube_connection
    if connection
      brands = connection.brand_labels_list
      return "#{brands.join(', ')} — #{connection.display_name}" if brands.any?

      return connection.display_name
    end

    "Autoria conn. #{autoria_youtube_connection_id}"
  end

  def youtube_watch_url
    return if youtube_video_id.blank?

    "https://www.youtube.com/watch?v=#{youtube_video_id}"
  end

  def status_label_ua
    {
      'pending' => 'В черзі',
      'downloading' => 'Завантаження відео',
      'uploading' => 'Upload на YouTube',
      'processing' => 'Обробка YouTube',
      'published' => 'Опубліковано',
      'failed' => 'Помилка'
    }.fetch(status, status)
  end

  def status_badge_class
    case status
    when 'published' then 'admin__badge--live'
    when 'failed' then 'admin__badge--off'
    when 'pending' then 'admin__badge--draft'
    else 'admin__badge'
    end
  end
end
