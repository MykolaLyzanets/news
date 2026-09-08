# frozen_string_literal: true

module NewsDesk
  class Score
    BREAKING = %w[
      breaking emergency earthquake explosion coup crash resign ceasefire
      hostage assass invasion missile collapse evacuate deadliest
    ].freeze

    def call(scope = default_scope)
      scope.find_each { |event| apply(event) }
    end

    def default_scope
      Event.where(status: %w[open ready published]).recent.includes(:source_articles, :sources, :category, :post)
    end

    def apply(event)
      breakdown = {
        freshness: freshness(event),
        source_priority: source_priority(event),
        source_count: source_count(event),
        category: category_points(event),
        breaking: breaking_points(event),
        body: body_points(event),
        image: image_points(event),
        importance: importance(event)
      }
      total = breakdown.values.sum
      breaking = breakdown[:breaking] >= 10 || total >= 80
      next_status = event.status
      next_status = 'ready' unless %w[published ignored failed publishing].include?(next_status)
      event.update!(
        score: total,
        score_breakdown: breakdown.merge(total:),
        breaking:,
        status: next_status
      )
      breakdown.merge(total:)
    end

    private

    def freshness(event)
      hours = ((Time.current - (event.last_seen_at || event.created_at)) / 1.hour)
      return 20 if hours < 2
      return 14 if hours < 8
      return 8 if hours < 24

      2
    end

    def source_priority(event)
      priority = event.sources.map(&:priority).min || 40
      (30 - priority).clamp(0, 20)
    end

    def source_count(event)
      [event.source_articles.map(&:source_id).uniq.size * 5, 20].min
    end

    def category_points(event)
      event.category.present? ? 5 : 0
    end

    def breaking_points(event)
      hay = "#{event.title} #{event.source_articles.map(&:title).join(' ')}".downcase
      hits = BREAKING.count { |word| hay.include?(word) }
      [hits * 5, 15].min
    end

    def body_points(event)
      event.source_articles.any?(&:full_story?) ? 10 : 0
    end

    def image_points(event)
      event.photo? ? 5 : 0
    end

    def importance(event)
      independent = event.source_articles.map(&:source_id).uniq.size
      names = Array(event.entities['names']).size
      numbers = Array(event.entities['numbers']).size
      [(independent * 5) + [names, 6].min + [numbers, 4].min, 25].min
    end
  end
end
