# frozen_string_literal: true

module Ai
  class OpenAiResponseService
    API_URL = 'https://api.openai.com/v1/responses'
    DEFAULT_MODEL = 'gpt-4.1-mini'

    def initialize(input:, model: DEFAULT_MODEL, store: false, max_output_tokens: nil)
      @input = input
      @model = model
      @store = store
      @max_output_tokens = max_output_tokens
    end

    def call
      return { success: false, error: 'No OpenAI key' } unless Ai::Config.configured?

      response = post_request
      return { success: false, error: "API request failed: #{response.status}" } unless response.success?

      parse_success(response)
    rescue StandardError => e
      Rails.logger.error("OpenAiResponseService: #{e.class} - #{e.message}")
      { success: false, error: e.message }
    end

    private

    def post_request
      Faraday.post(API_URL) do |req|
        req.headers['Authorization'] = "Bearer #{Ai::Config.api_key}"
        req.headers['Content-Type'] = 'application/json'
        req.options.timeout = 60
        req.options.open_timeout = 10
        req.body = request_body.to_json
      end
    end

    def request_body
      body = { model: @model, input: @input, store: @store }
      body[:max_output_tokens] = @max_output_tokens if @max_output_tokens
      body
    end

    def parse_success(response)
      parsed = JSON.parse(response.body)
      text = extract_output_text(parsed)
      if text
        { success: true, text:, response_id: parsed['id'], raw: parsed }
      else
        { success: false, error: parsed.dig('error', 'message') || 'No output text', raw: parsed }
      end
    end

    def extract_output_text(parsed)
      output = parsed['output']
      return nil unless output.is_a?(Array) && output.any?

      first_output = output.first
      content = first_output.is_a?(Hash) && first_output['content']
      return nil unless content.is_a?(Array) && content.any?

      first_content = content.first
      first_content.is_a?(Hash) ? first_content['text'] : nil
    end
  end
end
