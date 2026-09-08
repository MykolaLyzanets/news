# frozen_string_literal: true

class Event < ApplicationRecord
  STATUSES = %w[open ready publishing published ignored failed].freeze

  belongs_to :category
  has_many :source_articles, dependent: :nullify
  has_many :sources, through: :source_articles
  has_one :post, dependent: :nullify
  has_many :event_topics, dependent: :destroy
  has_many :topics, through: :event_topics

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :score, numericality: { only_integer: true }

  scope :open_desk, -> { where(status: %w[open ready]) }
  scope :scored, -> { order(score: :desc, id: :asc) }
  scope :recent, -> { where('first_seen_at >= ?', Post.fresh_since) }

  def published?
    status == 'published' && post&.published?
  end

  def photo?
    source_articles.any?(&:photo?)
  end

  def best_article
    source_articles.max_by { |item| [(item.photo? ? 1 : 0), item.text.to_s.length] }
  end

  def refresh_counts!
    update_columns(
      source_count: source_articles.count,
      last_seen_at: source_articles.maximum(:published_at) || Time.current
    )
  end

  def absorb!(other)
    raise ArgumentError, 'cannot merge an event with itself' if other.id == id

    transaction do
      other.source_articles.update_all(event_id: id, status: 'clustered')
      other.event_topics.find_each do |link|
        event_topics.find_or_create_by!(topic_id: link.topic_id)
      end
      take_post_from!(other)
      other.post&.update!(published: false) if post && other.post && other.post.id != post.id
      other.update!(status: 'ignored')
      refresh_counts!
    end
    self
  end

  def split!(article_ids)
    articles = source_articles.where(id: article_ids)
    return if articles.empty?

    transaction do
      first = articles.first
      child = Event.create!(
        category: first.category,
        title: first.title,
        status: 'open',
        match_key: first.match_key,
        first_seen_at: first.published_at || Time.current,
        last_seen_at: first.published_at || Time.current,
        entities: first.entities
      )
      articles.update_all(event_id: child.id, status: 'clustered')
      child.refresh_counts!
      refresh_counts!
      child
    end
  end

  def summaries
    source_articles.includes(:source).map do |item|
      {
        source: item.source&.name,
        title: item.title,
        summary: item.intro.presence || item.text.to_s.truncate(400),
        url: item.source_url,
        date: item.published_at
      }
    end
  end

  private

  def take_post_from!(other)
    return unless other.post
    return if post

    other.post.update!(event_id: id)
    update_columns(status: 'published', published_at: other.published_at || other.post.date)
  end
end
