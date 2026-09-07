# frozen_string_literal: true

module Posts
  class RewriteJob < ApplicationJob
    queue_as :default

    def perform(post_id)
      post = Post.find_by(id: post_id)
      return unless post
      return if post.ai_done?

      result = RewriteService.new(post).call
      post.reload
      if result[:ok] && post.text.to_s.squish.present?
        post.update!(published: true, date: post.date || Time.current)
        RankService.new.call
      end
    end
  end
end
