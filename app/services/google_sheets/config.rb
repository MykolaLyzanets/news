# frozen_string_literal: true

module GoogleSheets
  class Config
    SPREADSHEET_ID = '1-rZZCXEo1dnqxgm4F9gEzpbN4vx-LJHlK0MwHh9rlFc'
    SHEET_NAME = 'News link'

    def self.configured?
      service_account_json.present?
    end

    def self.spreadsheet_id
      SPREADSHEET_ID
    end

    def self.sheet_name
      SHEET_NAME
    end

    def self.service_account_json
      SiteSetting.current.google_sheets_service_account_json.to_s.strip.presence
    end
  end
end
