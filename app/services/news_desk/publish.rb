# frozen_string_literal: true

module NewsDesk
  class Publish
    def initialize(extractor: Ai::FactExtractService.new,
                   synthesizer: Ai::SynthesizeService.new,
                   quality: Ai::QualityCheckService.new)
      @extractor = extractor
      @synthesizer = synthesizer
      @quality = quality
    end

    def call
      published = []
      Config.publish_batch.times do
        reserved = reserve
        break if %i[full none].include?(reserved)
        next unless reserved.is_a?(Event)

        payload = build_article(reserved, replacing: false)
        next unless payload

        outcome = finalize_new(reserved, payload)
        break if outcome == :full

        published << outcome if outcome
      end
      refresh_published
      published
    end

    def regenerate(event)
      event = Event.find(event.id)
      if event.post
        update_existing(event)
      else
        publish_new(event)
      end
    end

    private

    def publish_new(event)
      reserved = reserve(event)
      return reserved if reserved == :full
      return unless reserved.is_a?(Event)

      payload = build_article(reserved, replacing: false)
      return unless payload

      finalize_new(reserved, payload)
    end

    def update_existing(event)
      payload = build_article(event, replacing: true)
      return unless payload

      update_post(event.post, payload)
      finish(event, event.post) if event.post.published?
      event.post
    rescue StandardError => e
      mark_failure(event, e.message)
      nil
    end

    def reserve(event = nil)
      Quota.with_lock do
        return :full if Quota.full?

        target = event ? Event.lock.find_by(id: event.id) : lock_next_eligible
        return :none unless target
        return if target.post

        target.touch if target.status == 'publishing'
        target.update!(status: 'publishing') unless target.status == 'publishing'
        target
      end
    end

    def lock_next_eligible
      ranked_eligible.each do |item|
        locked = Event.lock.find_by(id: item.id)
        next if locked.nil? || locked.post || locked.status == 'publishing'

        return locked
      end
      nil
    end

    def ranked_eligible
      counts = Post.published_today.group(:category_id).count
      Event.open_desk.recent.includes(:source_articles, :sources, :category, :post)
           .select { |event| eligible?(event) }
           .sort_by { |event| [event.breaking? ? 0 : 1, -event.score, counts[event.category_id].to_i, event.id] }
    end

    def eligible?(event)
      return false if event.post.present?
      return false if event.score < Config.min_score
      return false if event.ai_attempts >= Config.ai_retries
      return false if %w[failed ignored publishing].include?(event.status)
      return false if event.source_articles.none?(&:full_story?)

      breaking_ready?(event) || gathered?(event)
    end

    def breaking_ready?(event)
      event.breaking? && event.sources.any?(&:reliable?)
    end

    def gathered?(event)
      unique_sources(event) >= 2 || waited?(event)
    end

    def unique_sources(event)
      event.source_articles.map(&:source_id).uniq.size
    end

    def waited?(event)
      seen = event.first_seen_at
      seen.present? && seen <= Config.wait_minutes.minutes.ago
    end

    def finalize_new(event, payload)
      Quota.with_lock do
        event = Event.lock.find(event.id)
        return event.post if event.post
        if Quota.used >= Config.daily_limit
          release_reservation(event)
          return :full
        end

        post = insert_post(event, payload)
        finish(event, post)
        post
      end
    rescue ActiveRecord::RecordNotUnique
      Event.find(event.id).post
    rescue StandardError => e
      mark_failure(event, e.message)
      nil
    end

    def build_article(event, replacing: false)
      facts = @extractor.call(event)
      unless facts[:ok]
        mark_failure(event, facts[:error])
        return
      end
      event.update!(facts: facts[:facts], ai_status: 'facts')

      article = @synthesizer.call(event)
      unless article[:ok]
        mark_failure(event, article[:error])
        return
      end

      quality = @quality.call(event, article, replacing:)
      unless quality[:ok]
        mark_failure(event, quality[:error])
        return
      end

      article
    end

    def insert_post(event, article)
      source_article = event.best_article
      post = Post.new(generated_attrs(event, source_article, article))
      copy_image(post, source_article)
      post.save!
      post
    end

    def update_post(post, article)
      post.update!(
        title: article[:title],
        intro: article[:intro],
        text: article[:text],
        minutes: minutes_for(article[:text]),
        ai_done: true,
        ai_error: nil,
        quality_status: 'passed'
      )
    end

    def generated_attrs(event, source_article, article)
      {
        event:,
        category: event.category,
        source: source_article&.source,
        source_url: unique_source_url(source_article),
        fingerprint: unique_fingerprint(source_article),
        title: article[:title],
        intro: article[:intro],
        text: article[:text],
        original_title: source_article&.original_title,
        original_intro: source_article&.original_intro,
        original_text: source_article&.original_text,
        label: event.category.name,
        source_image_url: source_article&.source_image_url,
        date: Time.current,
        published: true,
        breaking: event.breaking?,
        ai_done: true,
        quality_status: 'passed',
        minutes: minutes_for(article[:text])
      }
    end

    def unique_source_url(source_article)
      url = source_article&.source_url
      return if url.blank? || Post.exists?(source_url: url)

      url
    end

    def unique_fingerprint(source_article)
      fingerprint = source_article&.fingerprint
      return if fingerprint.blank? || Post.exists?(fingerprint:)

      fingerprint
    end

    def copy_image(post, source_article)
      return unless source_article

      post.source_image_url = source_article.source_image_url if source_article.source_image_url.present?
      return unless source_article.real_image?

      File.open(source_article.image.path) { |file| post.image = file }
    rescue StandardError => e
      Log.error(e.message, event: post.event, operation: 'image_copy')
    end

    def finish(event, post)
      names = Array(event.facts['entities']) + Array(event.entities['names'])
      event.topics = Topic.upsert_named!(names) if names.any?
      event.update!(
        status: 'published',
        published_at: post.date,
        ai_status: 'published',
        ai_error: nil,
        quality_status: 'passed',
        title: post.title.presence || event.title
      )
      Log.info("Published #{post.title}", event:, post:, operation: 'publish')
    end

    def refresh_published
      Event.where(status: 'published').recent.includes(:post, :source_articles, :sources,
                                                       :category).find_each do |event|
        next unless stale_coverage?(event)

        update_existing(event)
      rescue StandardError => e
        mark_failure(event, e.message)
      end
    end

    def stale_coverage?(event)
      event.post.present? &&
        event.last_seen_at.present? &&
        event.last_seen_at > event.post.updated_at &&
        event.ai_attempts < Config.ai_retries
    end

    def minutes_for(text)
      [(text.to_s.split.size / 200.0).ceil, 1].max
    end

    def release_reservation(event)
      return unless event.status == 'publishing'

      event.update!(status: 'ready')
    end

    def mark_failure(event, error)
      return unless event

      event.reload
      attempts = event.ai_attempts + 1
      attrs = {
        ai_attempts: attempts,
        ai_error: error.to_s.truncate(1000),
        ai_status: 'error',
        quality_status: 'failed'
      }
      attrs[:status] = failure_status(event, attempts)
      event.update!(attrs)
      Log.error(error, event:, operation: 'publish')
    end

    def failure_status(event, attempts)
      return event.status if event.status == 'published'
      return 'failed' if attempts >= Config.ai_retries

      'ready'
    end
  end
end
