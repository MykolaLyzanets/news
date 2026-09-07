# frozen_string_literal: true

module NewsSources
  class Page
    MIN_WORDS = 80
    JUNK = /
      cookie|subscribe|newsletter|advertisement|sign in|sign up|log in|
      related stories|skip to|enable javascript|we use cookies|
      accept all|privacy policy|share this|follow us|listen to this
    /ix

    SELECTORS = [
      '[itemprop="articleBody"]',
      '[data-gu-name="body"]',
      '.c-article-content',
      '.wysiwyg',
      '.post-content',
      'article',
      'main',
      '#main-content'
    ].freeze

    def initialize(client: Client.new)
      @client = client
    end

    def text(url)
      html = @client.get_html(url)
      doc = Nokogiri::HTML(html)
      doc.css('script, style, noscript, svg, iframe, form, nav, footer, aside, header, button').remove

      node = best_node(doc)
      return if node.blank?

      parts = node.css('p, h2, h3').map { |el| el.text.squish }.reject { |line| junk?(line) }
      body = parts.join("\n\n")
      return if body.split.size < MIN_WORDS

      body
    rescue StandardError => e
      Rails.logger.warn("[NewsSource] Page skip: #{e.message}")
      nil
    end

    private

    def best_node(doc)
      SELECTORS.each do |sel|
        best = doc.css(sel).max_by { |node| words_in(node) }
        return best if best && words_in(best) >= MIN_WORDS
      end

      nil
    end

    def words_in(node)
      node.css('p').text.split.size
    end

    def junk?(line)
      line.length < 25 || line.match?(JUNK)
    end
  end
end
