# frozen_string_literal: true

module Posts
  class Score
    SUPER = %w[
      breaking emergency attack war killed earthquake explosion coup crash
      resign ceasefire hostage assass pandemonium invasion missile strike
      deadliest collapse evacuate
    ].freeze

    def self.call(post)
      new(post).call
    end

    def self.super?(post)
      new(post).super_hit?
    end

    def initialize(post)
      @post = post
    end

    def call
      recency + source_weight + keyword + body
    end

    def super_hit?
      keyword >= 20
    end

    private

    def recency
      hours = ((Time.current - (@post.date || @post.created_at)) / 1.hour)
      return 40 if hours < 2
      return 25 if hours < 8
      return 12 if hours < 24

      4
    end

    def source_weight
      priority = @post.source&.priority || 20
      (25 - priority).clamp(0, 20)
    end

    def keyword
      hay = "#{@post.title} #{@post.intro} #{@post.source_title}".downcase
      hits = SUPER.count { |word| hay.include?(word) }
      hits * 12
    end

    def body
      @post.text.to_s.size > 180 ? 5 : 0
    end
  end
end
