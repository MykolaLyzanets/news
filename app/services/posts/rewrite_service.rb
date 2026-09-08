# frozen_string_literal: true

module Posts
  class RewriteService
    INPUT_LIMIT = 400

    def initialize(post)
      @post = post
    end

    def call
      return { ok: false, error: 'No text' } if @post.source_text.to_s.squish.blank?
      return { ok: false, error: 'No OpenAI key' } unless Ai::Config.configured?

      result = Ai::OpenAiResponseService.new(
        input: prompt,
        store: false,
        max_output_tokens: 80
      ).call
      return { ok: false, error: result[:error] } unless result[:success]

      parsed = parse_json(result[:text])
      title = parsed['title'].to_s.strip
      return { ok: false, error: 'Bad AI title' } if title.blank?

      @post.update!(title:, ai_done: true)
      { ok: true }
    rescue StandardError => e
      { ok: false, error: e.message }
    end

    private

    def prompt
      <<~TEXT
        Rewrite only the headline. Same facts and meaning. Do not add anything.
        Keep names, numbers, and places. English. JSON only:
        {"title":"..."}
        Title: #{@post.source_title}
        Text: #{@post.source_text.to_s.squish.truncate(INPUT_LIMIT)}
      TEXT
    end

    def parse_json(raw)
      json = raw.to_s[/{.*}/m]
      JSON.parse(json || '{}')
    rescue JSON::ParserError
      {}
    end
  end
end
