# frozen_string_literal: true

module NewsSources
  class Dedup
    def duplicate?(item)
      url = Normalize.url(item.source_url)
      return true if url.blank?
      return true if seen_url?(item.source_url, url)

      fingerprint = Normalize.fingerprint(item.title, item.content)
      fingerprint.present? && seen_fingerprint?(fingerprint)
    end

    private

    def seen_url?(*urls)
      keys = urls.compact.uniq
      SourceArticle.exists?(source_url: keys) || Post.exists?(source_url: keys)
    end

    def seen_fingerprint?(fingerprint)
      SourceArticle.exists?(fingerprint:) || Post.exists?(fingerprint:)
    end
  end
end
