# frozen_string_literal: true

module Admin
  class HomeController < BaseController
    def index
      @sources = Source.ordered.includes(:category)
      @posts_new = Post.where(published: false).count
      @posts_live = Post.visible.count
      @posts_today = NewsDesk::Quota.used
      @daily_limit = NewsDesk::Config.daily_limit
      @per_category_limit = NewsDesk::Config.per_category_limit
      today_counts = NewsDesk::Quota.used_by_category
      @today_by_category = Category.ordered.map { |category| [category, today_counts[category.id].to_i] }
      @events_open = Event.open_desk.count
      @sources_on = @sources.count(&:active?)
      @sources_off = @sources.size - @sources_on
      @ai_ready = Ai::Config.configured?
    end
  end
end
