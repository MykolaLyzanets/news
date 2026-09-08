# frozen_string_literal: true

module Ai
  class FactExtractService
    def call(event)
      return fail_result('No OpenAI key', event) unless Config.configured?

      result = Json.call(prompt(event), max_output_tokens: 1_400)
      return fail_result(result[:error], event) unless result[:success]

      data = result[:data]
      return fail_result('Empty facts', event) if data.blank?

      { ok: true, facts: data }
    rescue StandardError => e
      fail_result(e.message, event)
    end

    private

    def prompt(event)
      <<~TEXT
        Extract verified facts from these reports. Do not invent.
        Separate confirmed facts from uncertainty.
        Do not include outlet names in the extracted facts.
        JSON only:
        {"event":"...","facts":[],"entities":[],"locations":[],"dates":[],"numbers":[],"quotes":[],"claims":[],"uncertainties":[]}
        Reports: #{event.summaries.to_json}
      TEXT
    end

    def fail_result(error, event)
      NewsDesk::Log.error(error, event:, operation: 'fact_extract')
      { ok: false, error: }
    end
  end
end
