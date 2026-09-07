# frozen_string_literal: true

module Posts
  class RewriteAllJob < ApplicationJob
    queue_as :default

    def perform
      Post.pending_ai.find_each do |post|
        RewriteJob.perform_later(post.id)
      end
    end
  end
end
