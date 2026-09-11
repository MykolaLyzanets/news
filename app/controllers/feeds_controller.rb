# frozen_string_literal: true

class FeedsController < ApplicationController
  def show
    @posts = Post.visible.includes(:category, :source).newest.limit(50)
    render layout: false
  end
end
