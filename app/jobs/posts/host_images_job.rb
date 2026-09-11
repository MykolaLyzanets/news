# frozen_string_literal: true

module Posts
  class HostImagesJob < ApplicationJob
    queue_as :default

    def perform(post_id = nil)
      scope = post_id ? Post.where(id: post_id) : Post.visible
      scope.where.not(source_image_url: nil).where.not(source_image_url: '').find_each do |post|
        next if post.real_image?

        NewsSources::Image.new.attach(post, post.source_image_url, referer: post.source_url)
      end
    end
  end
end
