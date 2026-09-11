# frozen_string_literal: true

module NewsDesk
  class Config
    def self.daily_limit
      int('NEWS_DAILY_POST_LIMIT', 20)
    end

    def self.per_category_limit
      int('NEWS_PER_CATEGORY_LIMIT', 3)
    end

    def self.daily_target
      int('NEWS_DAILY_TARGET', 15)
    end

    def self.match_threshold
      float('NEWS_EVENT_MATCH_THRESHOLD', 0.85)
    end

    def self.cheap_threshold
      float('NEWS_EVENT_CHEAP_THRESHOLD', 0.72)
    end

    def self.review_threshold
      float('NEWS_EVENT_REVIEW_THRESHOLD', 0.4)
    end

    def self.min_words
      int('NEWS_MIN_ARTICLE_WORDS', 80)
    end

    def self.item_limit
      int('NEWS_SOURCES_ITEM_LIMIT', 6)
    end

    def self.publish_batch
      int('NEWS_PUBLISH_BATCH', 2)
    end

    def self.wait_minutes
      int('NEWS_EVENT_WAIT_MINUTES', 45)
    end

    def self.min_score
      int('NEWS_MIN_EVENT_SCORE', 40)
    end

    def self.ai_retries
      int('NEWS_AI_MAX_RETRIES', 2)
    end

    def self.reliable_priority
      int('NEWS_RELIABLE_PRIORITY', 20)
    end

    def self.min_publish_words
      int('NEWS_MIN_PUBLISH_WORDS', 220)
    end

    def self.quota_lock
      872_001
    end

    def self.cluster_lock
      872_002
    end

    def self.int(name, default)
      Integer(ENV.fetch(name, default))
    end

    def self.float(name, default)
      Float(ENV.fetch(name, default))
    end
  end
end
