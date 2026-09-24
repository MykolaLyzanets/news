# frozen_string_literal: true

module GoogleSheets
  class AppendNewsLinkJob < ApplicationJob
    queue_as :default

    def perform(post_id)
      return unless GoogleSheets::Config.configured?

      post = Post.find_by(id: post_id)
      return unless post&.published?

      NewsLinks.new.append(post)
    rescue Google::Apis::Error, GoogleSheets::Client::Error => e
      NewsDesk::Log.error(e.message, post:, operation: 'google_sheets_append')
      raise
    end
  end
end
