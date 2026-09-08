# frozen_string_literal: true

module NewsDesk
  class Match
    def initialize(matcher: Ai::EventMatchService.new)
      @matcher = matcher
    end

    def call(article, event)
      cheap = cheap_score(article, event)
      return result(true, cheap, 'cheap') if cheap >= Config.cheap_threshold
      return result(false, cheap, 'cheap') if cheap < Config.review_threshold

      semantic(article, event, cheap)
    end

    def cheap_score(article, event)
      scores = event.source_articles.map { |other| pair_score(article, other) }
      scores << Tokens.cheap_score(
        { title: article.title, entities: article.entities, category_id: article.category_id },
        { title: event.title, entities: event.entities, category_id: event.category_id }
      )
      scores.max || 0.0
    end

    private

    def pair_score(left, right)
      Tokens.cheap_score(
        { title: left.title, entities: left.entities, category_id: left.category_id },
        { title: right.title, entities: right.entities, category_id: right.category_id }
      )
    end

    def semantic(article, event, cheap)
      payload = @matcher.call(summary_for(article), event_summary(event))
      if payload[:error]
        Log.error(payload[:error], event:, source: article.source, operation: 'event_match')
        return result(false, cheap, 'ai_error')
      end

      same = payload[:same_event] && payload[:confidence] >= Config.match_threshold
      result(same, payload[:confidence], 'semantic')
    end

    def summary_for(article)
      {
        source: article.source&.name,
        title: article.title,
        summary: article.intro.presence || article.text.to_s.truncate(400),
        date: article.published_at,
        entities: article.entities
      }
    end

    def event_summary(event)
      {
        title: event.title,
        sources: event.summaries,
        entities: event.entities
      }
    end

    def result(same, confidence, layer)
      { same:, confidence:, layer: }
    end
  end
end
