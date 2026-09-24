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

    def clear_sheet_data!
      api_call do
        service.clear_values(
          Config.spreadsheet_id,
          "#{quoted_sheet}!A:B",
          Google::Apis::SheetsV4::ClearValuesRequest.new
        )
      end
    end

    def write_rows!(rows)
      return if rows.empty?

      api_call do
        service.update_spreadsheet_value(
          Config.spreadsheet_id,
          data_range(rows.size),
          Google::Apis::SheetsV4::ValueRange.new(values: rows),
          value_input_option: 'RAW'
        )
      end
    end

    def append_rows!(rows)
      return if rows.empty?

      api_call do
        service.append_spreadsheet_value(
          Config.spreadsheet_id,
          append_range,
          Google::Apis::SheetsV4::ValueRange.new(values: rows),
          value_input_option: 'RAW',
          insert_data_option: 'INSERT_ROWS'
        )
      end
    end

    private

    attr_reader :service

    def sheet_title
      @sheet_title ||= resolve_sheet_title
    end

    def resolve_sheet_title
      api_call do
        spreadsheet = service.get_spreadsheet(Config.spreadsheet_id, fields: 'sheets.properties')
        by_gid = spreadsheet.sheets.find { |sheet| sheet.properties.sheet_id == Config.sheet_gid }
        title = by_gid&.properties&.title.presence
        title || Config.sheet_name
      end
    end

    def api_call
      yield
    rescue Google::Apis::Error => e
      raise Error, ErrorMessage.from(e)
    end

    def quoted_sheet
      "'#{sheet_title.gsub("'", "''")}'"
    end

    def data_range(row_count)
      "#{quoted_sheet}!A1:B#{row_count}"
    end

    def append_range
      "#{quoted_sheet}!A:B"
    end

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
