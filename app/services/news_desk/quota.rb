# frozen_string_literal: true

module NewsDesk
  class Quota
    STALE_AFTER = 30.minutes

    def self.used
      Post.published_today.count
    end

    def self.reserved
      Event.where(status: 'publishing').count
    end

    def self.occupancy
      used + reserved
    end

    def self.remaining
      [Config.daily_limit - occupancy, 0].max
    end

    def self.full?
      occupancy >= Config.daily_limit
    end

    def self.used_by_category
      Post.published_today.group(:category_id).count
    end

    def self.reserved_by_category
      Event.where(status: 'publishing').group(:category_id).count
    end

    def self.occupancy_by_category
      used_by_category.merge(reserved_by_category) { |_id, live, held| live + held }
    end

    def self.used_in(category_id)
      used_by_category[category_id].to_i
    end

    def self.occupancy_in(category_id)
      occupancy_by_category[category_id].to_i
    end

    def self.category_full?(category_id)
      occupancy_in(category_id) >= Config.per_category_limit
    end

    def self.category_used_full?(category_id)
      used_in(category_id) >= Config.per_category_limit
    end

    def self.message(code)
      case code
      when :full
        'Daily publication limit reached'
      when :category_full
        "This category already has #{Config.per_category_limit} stories today"
      end
    end

    def self.with_lock
      Lock.with(Config.quota_lock) do
        expire_stale!
        yield
      end
    end

    def self.claim_publication!(post)
      with_lock do
        post = Post.lock.find(post.id)
        return post if post.published?
        return :full if used >= Config.daily_limit
        return :category_full if category_used_full?(post.category_id)

        post.update!(published: true, date: post.date || Time.current)
        sync_event!(post)
        post
      end
    end

    def self.expire_stale!
      Event.where(status: 'publishing').where('updated_at < ?', STALE_AFTER.ago)
           .update_all(status: 'ready', updated_at: Time.current)
    end

    def self.sync_event!(post)
      event = post.event
      return unless event

      event.update!(status: 'published', published_at: post.date) unless event.status == 'published'
    end
  end
end
