# frozen_string_literal: true

module NewsDesk
  class Related
    def self.call(post, limit: 5)
      new(post, limit:).call
    end

    def initialize(post, limit: 5)
      @post = post
      @limit = limit
    end

    def call
      ids = []
      ids.concat(same_topics)
      ids.concat(same_category)
      Post.visible.where(id: ids.uniq).where.not(id: @post.id)
          .includes(:category, :source, event: :topics)
          .sort_by { |item| -rank(item) }
          .first(@limit)
    end

    private

    def same_topics
      topic_ids = @post.event&.topic_ids || []
      return [] if topic_ids.empty?

      Event.joins(:event_topics, :post)
           .merge(Post.visible)
           .where(event_topics: { topic_id: topic_ids })
           .where.not(id: @post.event_id)
           .limit(20)
           .pluck('posts.id')
    end

    def same_category
      Post.visible.where(category_id: @post.category_id).where.not(id: @post.id).newest.limit(8).pluck(:id)
    end

    def rank(item)
      score = 0
      score += 40 if shared_topics?(item)
      score += 12 if item.category_id == @post.category_id
      hours = ((Time.current - (item.date || item.created_at)) / 1.hour)
      score += hours < 48 ? 10 : 3
      score += item.event&.score.to_i / 10
      score
    end

    def shared_topics?(item)
      return false unless @post.event && item.event

      @post.event.topic_ids.intersect?(item.event.topic_ids)
    end
  end
end
