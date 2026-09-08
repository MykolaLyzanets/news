# frozen_string_literal: true

module Ai
  class EventMatchService
    def call(left, right)
      return { same_event: false, confidence: 0.0, error: 'No OpenAI key' } unless Config.configured?

      result = Json.call(prompt(left, right), max_output_tokens: 200)
      return { same_event: false, confidence: 0.0, error: result[:error] } unless result[:success]

      data = result[:data]
      {
        same_event: data['same_event'] == true,
        confidence: data['confidence'].to_f.clamp(0.0, 1.0)
      }
    rescue StandardError => e
      { same_event: false, confidence: 0.0, error: e.message }
    end

    private

    def prompt(left, right)
      <<~TEXT
        Decide if these two news items describe the same real-world event.
        Use only the metadata. Do not invent facts.
        JSON only: {"same_event":true,"confidence":0.0}
        Item A: #{left.to_json}
        Item B: #{right.to_json}
      TEXT
    end
  end
end
