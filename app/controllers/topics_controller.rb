# frozen_string_literal: true

class TopicsController < ApplicationController
  def show
    @topic = Topic.find_by(slug: params[:id])
    posts = if @topic
              Post.visible.joins(event: :topics).where(topics: { id: @topic.id })
                  .includes(:source, :category).newest
            else
              Post.none
            end
    @posts = posts.limit(40).to_a
    return render_not_found if @topic.blank? || @posts.empty?

    @noindex = true

    @lead_post = @posts.find(&:real_image?) || @posts.first
    @coverage = @posts.reject { |post| post.id == @lead_post.id }
    @related = NewsDesk::Related.call(@lead_post)
    @most_read = Post.visible.fresh.includes(:category).popular.limit(5)
  end
end
