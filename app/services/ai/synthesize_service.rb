# frozen_string_literal: true

module Ai
  class SynthesizeService
    def call(event)
      return fail_result('No OpenAI key', event) unless Config.configured?
      return fail_result('No facts', event) if event.facts.blank?

      result = Json.call(prompt(event), max_output_tokens: 2_400)
      return fail_result(result[:error], event) unless result[:success]

      data = result[:data]
      title = data['title'].to_s.strip
      text = data['text'].to_s.strip
      intro = data['intro'].to_s.strip
      return fail_result('Empty article', event) if title.blank? || text.blank?

      { ok: true, title:, intro:, text: }
    rescue StandardError => e
      fail_result(e.message, event)
    end

    private

    def prompt(event)
      <<~TEXT
        Write an original news report from verified facts only.
        Do not rewrite any source sentence by sentence. Do not synonym-spin.
        Do not copy unique phrasing or the source structure. Do not invent facts.
        Use concise news English.
        Attribute facts to named sources when the facts include them.
        Do not hide that reporting is based on multiple accounts.
        Write as this site's own report, not as a copy of another outlet.
        Use short paragraphs. Put two or three section headings in the text
        on their own lines in Title Case when the facts support it.
        Pick length from confirmed facts: short 220-350 words, normal 350-600, important 600-1000.
        Do not pad. JSON only:
        {"title":"...","intro":"...","text":"..."}
        Event: #{event.title}
        Facts: #{event.facts.to_json}
      TEXT
    end

    def fail_result(error, event)
      NewsDesk::Log.error(error, event:, operation: 'synthesize')
      { ok: false, error: }
    end
  end
end
