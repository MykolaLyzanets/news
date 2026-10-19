# frozen_string_literal: true

module Youtube
  class ErrorTranslator
    REASON_KEYS = {
      'uploadlimitexceeded' => 'upload_limit_exceeded',
      'quotaexceeded' => 'quota_exceeded',
      'dailylimitexceeded' => 'quota_exceeded',
      'resourceexhausted' => 'quota_exceeded',
      'userratelimitexceeded' => 'rate_limit',
      'ratelimitexceeded' => 'rate_limit',
      'forbidden' => 'forbidden',
      'insufficientpermissions' => 'forbidden',
      'youtubesignuprequired' => 'channel_required',
      'unauthorized' => 'auth',
      'autherror' => 'auth',
      'invalidcredentials' => 'auth',
      'videonotfound' => 'video_not_found',
      'notfound' => 'video_not_found',
      'invalidvideometadata' => 'invalid_metadata',
      'invalidtitle' => 'invalid_metadata',
      'invaliddescription' => 'invalid_metadata',
      'failedpreprocessing' => 'processing_failed',
      'uploadaborted' => 'upload_aborted',
      'backenderror' => 'server',
      'internalerror' => 'server'
    }.freeze

    def self.call(error)
      new(error).call
    end

    def initialize(error)
      @error = error
    end

    def call
      reason = extract_reason
      key = REASON_KEYS[reason.to_s.downcase.gsub(/[^a-z]/, '')]
      return "YouTube: #{key}" if key.present?

      raw_message.truncate(240)
    end

    private

    def extract_reason
      from_body || from_message
    end

    def from_body
      body = @error.respond_to?(:body) ? @error.body : nil
      return if body.blank?

      parsed = body.is_a?(String) ? JSON.parse(body) : body
      errors = parsed.dig('error', 'errors')
      errors&.first&.fetch('reason', nil) || parsed.dig('error', 'status')
    rescue JSON::ParserError, TypeError
      nil
    end

    def from_message
      text = raw_message
      normalized = text.downcase.gsub(/[^a-z]/, '')
      hit = REASON_KEYS.keys.find { |reason| normalized.include?(reason) }
      return hit if hit.present?

      text[/uploadLimitExceeded/i].presence ||
        text[/\A([A-Za-z]+):/, 1].presence ||
        (text.match?(/\A[A-Za-z]+\z/) ? text : nil)
    end

    def raw_message
      @error.respond_to?(:message) ? @error.message.to_s : @error.to_s
    end
  end
end
