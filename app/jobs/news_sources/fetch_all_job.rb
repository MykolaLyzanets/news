# frozen_string_literal: true

module NewsSources
  class FetchAllJob < ApplicationJob
    queue_as :default

    def perform
      Source.active.ordered.find_each do |source|
        Fetch.new(source).call
      rescue StandardError => e
        Rails.logger.error("[NewsSource] #{source.name} Error: #{e.class} #{e.message}")
      end
    end
  end
end
