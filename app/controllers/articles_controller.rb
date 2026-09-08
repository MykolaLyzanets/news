# frozen_string_literal: true

class ArticlesController < ApplicationController
  def show
    @post = Post.visible.includes(:category, :source, event: [:topics, { source_articles: :source }])
                 .find_by(url: params[:id])
    return render template: 'home/not_found', status: :not_found unless @post

    @post.increment!(:views)
    @related = NewsDesk::Related.call(@post)
    @most_read = Post.visible.fresh.includes(:category).popular.limit(5)
    @more = Post.visible.where(category_id: @post.category_id).where.not(id: @post.id).newest.limit(3)
    @topics = @post.related_topics
  end
end
