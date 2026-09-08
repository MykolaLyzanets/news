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

      article = SourceArticle.create!(
        source:,
        category: source.category,
        source_url: url,
        fingerprint:,
        title: item.title,
        intro: (item.summary.presence || body).to_s.squish.truncate_words(36, omission: '…'),
        text: body,
        original_title: item.title,
        original_intro: item.summary,
        original_text: body,
        source_image_url: image_url,
        published_at: item.published_at || Time.current,
        status: 'pending',
        match_key: NewsDesk::Tokens.match_key(item.title),
        entities: NewsDesk::Tokens.entities(item.title, body)
      )
      images.attach(article, image_url)
      article
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      nil
    end

    private

    def enough_text?(body)
      body.to_s.split.size >= NewsDesk::Config.min_words
    end
  end
end
