# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    posts = Post.visible.fresh.includes(:category, :source).newest.to_a
    pictured = posts.select(&:photo?)
    @lead = pictured.find(&:main) || pictured.first
    used = [@lead&.id].compact

    @rail = unused(posts, used).first(2)
    used.concat(@rail.map(&:id))

    @latest = unused(posts, used).first(5)
    used.concat(@latest.map(&:id))

    @business_posts = unused(posts, used).select { |post| %w[business technology].include?(post.category.url) }.first(4)
    used.concat(@business_posts.map(&:id))

    @most_posts = Post.visible.fresh.includes(:category).popular.limit(4)
    @archive = unused(posts, used).first || @lead
  end

  def not_found
    render template: 'home/not_found', status: :not_found
  end

  private

  def unused(posts, used)
    posts.reject { |post| used.include?(post.id) }
  end
end
