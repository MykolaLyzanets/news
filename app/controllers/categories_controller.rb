# frozen_string_literal: true

class CategoriesController < ApplicationController
  SECTIONS = %w[world politics business technology science culture sport].freeze
  PER_PAGE = 20

  def show
    @section = params[:section]
    return render_not_found unless SECTIONS.include?(@section)

    @category = Category.find_by(url: @section)
    scope = @category ? @category.posts.visible.includes(:source, :event).newest : Post.none
    @per_page = PER_PAGE
    @total = scope.count
    @pages = [(@total.to_f / @per_page).ceil, 1].max
    @page = requested_page
    return render_not_found unless @page

    @posts = scope.offset((@page - 1) * @per_page).limit(@per_page).to_a
    @lead_post = @page == 1 ? (@posts.find(&:real_image?) || @posts.first) : nil
    rest = @posts.reject { |post| post.id == @lead_post&.id }
    @rail_posts = @page == 1 ? rest.first(3) : []
    @feed_posts = rest
  end

  private

  def requested_page
    return 1 if params[:page].blank?

    page = params[:page].to_i
    return if page < 1 || page > @pages

    page
  end
end
