# frozen_string_literal: true

class ArticlesController < ApplicationController
  CRAWLER = /bot|crawler|spider|slurp|bingpreview|facebookexternalhit|embed/i

  def show
    @post = Post.visible.includes(:category, :source, event: [:topics, { source_articles: :source }])
                 .find_by(url: params[:id])
    return render_not_found unless @post

    record_view
    @related = NewsDesk::Related.call(@post)
    @most_read = Post.visible.fresh.includes(:category).popular.limit(5)
    @more = Post.visible.where(category_id: @post.category_id).where.not(id: @post.id).newest.limit(3)
    @topics = @post.related_topics
  end

  private

  def record_view
    return if request.user_agent.to_s.match?(CRAWLER)

    Post.increment_counter(:views, @post.id)
  end
end
