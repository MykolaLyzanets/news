# frozen_string_literal: true

module Posts
  class RankService
    def call
      posts = Post.visible.fresh.includes(:source, :category).select(&:photo?)
      return if posts.empty?

      ranked = posts.sort_by { |post| -Score.call(post) }
      winner = ranked.first
      current = Post.big.to_a.find(&:photo?)

      switch = current.nil? ||
               current.id == winner.id ||
               Score.super?(winner) ||
               Score.call(winner) >= Score.call(current) + 8 ||
               current.date.blank? ||
               current.date < 8.hours.ago

      return unless switch

      Post.where(main: true).where.not(id: winner.id).update_all(main: false)
      attrs = { main: true }
      attrs[:breaking] = true if Score.super?(winner)
      winner.update!(attrs)
      Rails.logger.info("[NewsDesk] Home lead: #{winner.title}")
    end
  end
end
