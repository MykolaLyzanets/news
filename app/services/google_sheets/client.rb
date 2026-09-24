# frozen_string_literal: true

require 'google/apis/sheets_v4'
require 'googleauth'

module GoogleSheets
  class Client
    class Error < StandardError; end

    SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

    def initialize
      @service = Google::Apis::SheetsV4::SheetsService.new
      @service.authorization = authorizer
    end

    def clear_range(range)
      service.clear_values(Config.spreadsheet_id, range)
    end

    def update(range, rows)
      body = Google::Apis::SheetsV4::ValueRange.new(values: rows)
      service.update_spreadsheet_value(
        Config.spreadsheet_id,
        range,
        body,
        value_input_option: 'USER_ENTERED'
      )
    end

    def append(range, rows)
      body = Google::Apis::SheetsV4::ValueRange.new(values: rows)
      service.append_spreadsheet_value(
        Config.spreadsheet_id,
        range,
        body,
        value_input_option: 'USER_ENTERED',
        insert_data_option: 'INSERT_ROWS'
      )
    end

    private

    attr_reader :service

    def authorizer
      json = Config.service_account_json
      raise Error, 'Google service account JSON is not configured' if json.blank?

      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(json),
        scope: SCOPE
      )
    end
  end
end
