# frozen_string_literal: true

class CategoriesController < ApplicationController
  SECTIONS = %w[world politics business technology science culture sport].freeze

  def show
    @section = params[:section]
    return render template: 'home/not_found', status: :not_found unless SECTIONS.include?(@section)

    @category = Category.find_by(url: @section)
    @posts = @category ? @category.posts.visible.fresh.includes(:source).newest.to_a : []
    @lead_post = @posts.find(&:photo?)
    rest = @posts.reject { |post| post.id == @lead_post&.id }
    @rail_posts = rest.first(3)
    @feed_posts = rest
  end
end
