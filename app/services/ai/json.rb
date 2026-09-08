# frozen_string_literal: true

module Ai
  class Json
    def self.parse(raw)
      json = raw.to_s.gsub(/```json|```/, '')[/{.*}/m]
      JSON.parse(json || '{}')
    rescue JSON::ParserError
      {}
    end

    def self.call(prompt, max_output_tokens: 1_200)
      result = OpenAiResponseService.new(input: prompt, store: false, max_output_tokens:).call
      return result.merge(data: {}) unless result[:success]

      result.merge(data: parse(result[:text]))
    end
  end
end
