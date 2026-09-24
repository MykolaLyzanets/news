# frozen_string_literal: true

module GoogleSheets
  module ErrorMessage
    module_function

    def from(error)
      return error.message unless error.is_a?(Google::Apis::Error)

      body = error.body
      return error.message if body.blank?

      json = JSON.parse(body)
      message = json.dig('error', 'message')
      status = json.dig('error', 'status')
      return message if message.present? && status.blank?

      [status, message].compact.join(': ').presence || error.message
    rescue JSON::ParserError
      error.message
    end
  end
end
