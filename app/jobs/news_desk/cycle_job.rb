# frozen_string_literal: true

module NewsDesk
  class CycleJob < ApplicationJob
    queue_as :default

    def perform
      Rails.logger.info('[NewsDesk] Cycle started')
      NewsSources::FetchAllJob.perform_now
      Process.new.call
      Rails.logger.info('[NewsDesk] Cycle finished')
    end
  end
end
