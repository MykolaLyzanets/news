# frozen_string_literal: true

module NewsDesk
  class ClusterJob < ApplicationJob
    queue_as :default

    def perform
      Cluster.new.call
    end
  end
end
