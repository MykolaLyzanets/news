# frozen_string_literal: true

module NewsSources
  class Import
    def call(item)
      return if item.content.to_s.squish.blank?
      return unless Post.fresh?(item.published_at)

      source = item.source
      url = Normalize.url(item.source_url)
      fingerprint = Normalize.fingerprint(item.title, item.content)

      images = Image.new
      image_url = images.pick(item.image_url, url)
      page_text = Page.new.text(url)
      body = page_text.presence || item.content.presence || item.summary
      return unless enough_text?(body)

      post = Post.create!(
        category: source.category,
        source:,
        source_url: url,
        fingerprint:,
        title: item.title,
        intro: (item.summary.presence || body).to_s.squish.truncate_words(36, omission: '…'),
        text: body,
        original_title: item.title,
        original_intro: item.summary,
        original_text: item.content,
        label: source.category.name,
        source_image_url: image_url,
        date: item.published_at || Time.current,
        published: true,
        ai_done: false,
        minutes: [(body.to_s.split.size / 200.0).ceil, 1].max
      )
      images.attach(post, image_url)
      post
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      nil
    end

    private

    def enough_text?(body)
      body.to_s.split.size >= Post::MIN_WORDS
    end
  end
end
