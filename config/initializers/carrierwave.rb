# frozen_string_literal: true

CarrierWave.configure do |config|
  config.storage = :file
  config.cache_dir = Rails.root.join('tmp/uploads')
  config.ignore_integrity_errors = false
  config.ignore_processing_errors = false
  config.ignore_download_errors = false
end
