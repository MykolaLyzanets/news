# frozen_string_literal: true

module Ai
  class QualityCheckService
    def call(event, article, replacing: false)
      checks = structural(event, article, replacing:)
      return checks unless checks[:ok]
      return checks unless Config.configured?

      result = Json.call(prompt(event, article), max_output_tokens: 200)
      return checks unless result[:success]

      data = result[:data]
      return { ok: false, error: data['reason'].presence || 'AI quality check failed' } if data['pass'] == false

      checks
    rescue StandardError => e
      NewsDesk::Log.error(e.message, event:, operation: 'quality_check')
      { ok: false, error: e.message }
    end

    private

    def structural(event, article, replacing: false)
      title = article[:title].to_s.strip
      text = article[:text].to_s.strip
      words = text.split.size
      source = event.best_article

      return fail('Title missing') if title.blank?
      return fail('Content missing') if text.blank?
      return fail('Article too short') if words < NewsDesk::Config.min_publish_words
      return fail('Event missing') if event.blank?
      return fail('Category missing') if event.category.blank?
      return fail('Source missing') if source.blank?
      return fail('Source URL missing') if source.source_url.blank?
      return fail('Duplicate event post') if event.post.present? && !replacing

      { ok: true }
    end

    def prompt(event, article)
      <<~TEXT
        Check this news article against the facts. Flag invented claims or copied source sentences.
        JSON only: {"pass":true,"reason":""}
        Facts: #{event.facts.to_json}
        Article title: #{article[:title]}
        Article text: #{article[:text].to_s.truncate(2_000)}
      TEXT
    end

    def fail(error)
      { ok: false, error: }
    end
  end
end
