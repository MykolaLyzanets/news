# frozen_string_literal: true

module NewsDesk
  class Cluster
    def initialize(matcher: Match.new)
      @matcher = matcher
    end

    def call
      Lock.with(Config.cluster_lock) { cluster_pending }
    end

    def attach(article)
      return article.event if article.event_id.present?

      event = find_event(article) || open_event(article)
      article.update!(event:, status: 'clustered')
      merge_entities!(event, article)
      event.refresh_counts!
      event
    end

    private

    def cluster_pending
      SourceArticle.pending.fresh.includes(:source, :category).find_each do |article|
        attach(article)
      rescue StandardError => e
        Log.error(e.message, source: article.source, operation: 'cluster')
      end
    end

    def find_event(article)
      Event.recent.where.not(status: %w[ignored failed]).includes(:source_articles, :category).find do |event|
        @matcher.call(article, event)[:same]
      end
    end

    def open_event(article)
      Event.create!(
        category: article.category,
        title: article.title,
        status: 'open',
        match_key: article.match_key,
        first_seen_at: article.published_at || Time.current,
        last_seen_at: article.published_at || Time.current,
        entities: article.entities
      )
    end

    def merge_entities!(event, article)
      merged = Tokens.entities(event.title, article.text)
      %w[keywords names numbers dates].each do |key|
        merged[key] = (Array(event.entities[key]) + Array(article.entities[key]) + Array(merged[key])).uniq
      end
      names = merged['names']
      event.update_columns(entities: merged)
      Topic.upsert_named!(names).each do |topic|
        event.event_topics.find_or_create_by!(topic:)
      end
    end
  end
end
