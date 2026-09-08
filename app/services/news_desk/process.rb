# frozen_string_literal: true

module NewsDesk
  class Process
    def call
      Cluster.new.call
      Score.new.call
      Publish.new.call
      Posts::RankService.new.call
    end
  end
end
