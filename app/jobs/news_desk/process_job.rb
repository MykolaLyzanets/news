# frozen_string_literal: true

module NewsDesk
  class ProcessJob < ApplicationJob
    queue_as :default

    def perform
      Process.new.call
    end
  end
end
