# frozen_string_literal: true

module NewsDesk
  class ScoreEventsJob < ApplicationJob
    queue_as :default

    def perform
      Score.new.call
    end
  end
end
