# frozen_string_literal: true

namespace :google_sheets do
  desc 'Export all live news links to the Google Sheet (tab News link)'
  task sync_news_links: :environment do
    unless GoogleSheets::Config.configured?
      abort 'Google Sheets is not configured. Add service account JSON in Admin → Settings.'
    end

    GoogleSheets::NewsLinks.new.sync_all!
    puts 'Synced all published posts to Google Sheets.'
  end
end
