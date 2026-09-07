# frozen_string_literal: true

module NewsSources
  class FetchJob < ApplicationJob
    queue_as :default

    def perform(source_id)
      source = Source.find_by(id: source_id)
      return unless source&.active?

      Fetch.new(source).call
      NewsDesk::Process.new.call
    end
  end
end
