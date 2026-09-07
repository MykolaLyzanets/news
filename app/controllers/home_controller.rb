# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    posts = Post.visible.fresh.includes(:category, :source).newest.to_a
    pictured = posts.select(&:photo?)
    @lead = pictured.find(&:main) || pictured.first
    rest = posts.reject { |post| post.id == @lead&.id }
    @rail = rest.first(3)
    @latest = rest.first(5)
    @business_posts = rest.select { |post| %w[business technology].include?(post.category.url) }.first(4)
    @most_posts = Post.visible.fresh.includes(:category).popular.limit(4)
  end

  def not_found
    render template: 'home/not_found', status: :not_found
  end
end
