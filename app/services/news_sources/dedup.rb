# frozen_string_literal: true

module NewsSources
  class Dedup
    def duplicate?(item)
      url = Normalize.url(item.source_url)
      return true if url.blank?
      return true if Post.exists?(source_url: [item.source_url, url].uniq)

      fingerprint = Normalize.fingerprint(item.title, item.content)
      fingerprint.present? && Post.exists?(fingerprint:)
    end
  end
end
