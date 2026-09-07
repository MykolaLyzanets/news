# frozen_string_literal: true

module Admin
  class HomeController < BaseController
    def index
      @sources = Source.ordered.includes(:category)
      @posts_new = Post.where(published: false).count
      @posts_live = Post.visible.count
      @sources_on = @sources.count(&:active?)
      @sources_off = @sources.size - @sources_on
      @ai_ready = Ai::Config.configured?
    end
  end
end
