# frozen_string_literal: true

module NewsDesk
  class Process
    def call
      drop_empty
      hide_thin
      hide_stale
      publish_ready
      Posts::RankService.new.call
    end

    private

    def drop_empty
      Post.where("text IS NULL OR btrim(text) = ''").delete_all
    end

    def hide_thin
      Post.visible.find_each do |post|
        next if post.full_story?

        post.update_columns(published: false, main: false, breaking: false)
      end
    end

    def hide_stale
      Post.where('date < ?', Post.fresh_since).where(published: true)
          .update_all(published: false, main: false, breaking: false)
    end

    def publish_ready
      Post.where(published: false).fresh.find_each do |post|
        next if post.title.blank? || !post.full_story?

        post.update!(published: true, date: post.date || Time.current)
      end
    end
  end
end
