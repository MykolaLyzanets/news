# frozen_string_literal: true

module NewsDesk
  class PublishDailyEventsJob < ApplicationJob
    queue_as :default

    def perform
      Publish.new.call
    end
  end
end
