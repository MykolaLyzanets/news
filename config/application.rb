# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in the Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module News
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.i18n.available_locales = %i[en]
    config.i18n.default_locale = :en

    config.i18n.fallbacks = true

    config.autoload_paths += %W[#{config.root}/lib]

    config.active_job.queue_adapter = :sidekiq
  end
end
