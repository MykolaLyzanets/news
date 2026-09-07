# frozen_string_literal: true

class ArticlesController < ApplicationController
  def show
    @post = Post.visible.find_by(url: params[:id])
    return render template: 'home/not_found', status: :not_found unless @post

    @post.increment!(:views)
    @related = Post.visible.fresh.where.not(id: @post.id).newest.limit(3)
    @most_read = Post.visible.fresh.includes(:category).popular.limit(5)
    @more = Post.visible.fresh.where(category_id: @post.category_id).where.not(id: @post.id).newest.limit(3)
  end
end
