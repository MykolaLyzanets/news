# frozen_string_literal: true

require 'rss'

module NewsSources
  module Parsers
    class Rss < Base
      def items
        feed = RSS::Parser.parse(@body, false)
        raise NewsSources::Client::Error, 'Malformed feed XML' if feed.nil?

        entries(feed).filter_map { |entry| build_item(entry) }
      rescue RSS::Error => e
        raise NewsSources::Client::Error, "Malformed feed XML: #{e.message}"
      end

      private

      def entries(feed)
        if feed.respond_to?(:items) && feed.items
          feed.items
        elsif feed.respond_to?(:entries) && feed.entries
          feed.entries
        else
          []
        end
      end

      def build_item(entry)
        title = Normalize.title(entry_title(entry))
        return if title.blank?

        content = Normalize.text(entry_content(entry))
        summary = Normalize.text(entry_summary(entry))
        content = summary if content.blank?
        return if content.blank?

        summary = content.truncate(280) if summary.blank?
        link = Normalize.url(entry_link(entry), base: @source.feed_url)
        return if link.blank?

        NewsSources::Item.new(
          title:,
          content:,
          summary:,
          source_url: link,
          image_url: image_for(entry, link),
          published_at: entry_date(entry),
          author: entry_author(entry),
          source: @source
        )
      end

      def image_for(entry, link)
        from_xml = xml_images[link].presence || xml_images[Normalize.url(entry_guid(entry), base: @source.feed_url)]
        raw = from_xml.presence || entry_image(entry)
        url = Normalize.url(raw, base: @source.feed_url)
        url if NewsSources::Image.usable?(url)
      end

      def entry_guid(entry)
        return entry.guid.content if entry.respond_to?(:guid) && entry.guid.respond_to?(:content)
        return entry.guid if entry.respond_to?(:guid) && entry.guid.is_a?(String)
        return entry.id.content if entry.respond_to?(:id) && entry.id.respond_to?(:content)
        return entry.id if entry.respond_to?(:id)

        nil
      end

      def xml_images
        @xml_images ||= begin
          doc = Nokogiri::XML(@body)
          images = {}
          doc.xpath('//*[local-name()="item"] | //*[local-name()="entry"]').each do |node|
            url = image_from_xml(node)
            next if url.blank?

            item_keys(node).each { |key| images[key] = url }
          end
          images
        end
      end

      def item_keys(node)
        keys = []
        link = node.at_xpath('./*[local-name()="link"]')
        if link
          href = link['href'].presence || link.text
          keys << Normalize.url(href, base: @source.feed_url)
        end
        guid = node.at_xpath('./*[local-name()="guid"] | ./*[local-name()="id"]')&.text
        keys << Normalize.url(guid, base: @source.feed_url) if guid.present?
        keys.reject(&:blank?).uniq
      end

      def image_from_xml(node)
        candidates = []

        node.xpath('.//*[local-name()="thumbnail"][@url]').each do |thumb|
          candidates << [thumb['width'].to_i, thumb['url']]
        end

        node.xpath('.//*[local-name()="content"][@url]').each do |media|
          next unless image_type?(media['type'], media['url']) || media['medium'].to_s == 'image' || media['url'].present?

          candidates << [media['width'].to_i, media['url']]
        end

        enclosure = node.at_xpath('.//*[local-name()="enclosure"][@url]')
        if enclosure && image_type?(enclosure['type'], enclosure['url'])
          candidates << [enclosure['length'].to_i, enclosure['url']]
        end

        itunes = node.at_xpath('.//*[local-name()="image"]/@href')&.value
        candidates << [0, itunes] if itunes.present?

        html = node.xpath('.//*[local-name()="description"] | .//*[local-name()="summary"] | .//*[local-name()="encoded"]').map(&:text).join(' ')
        from_html = html[/img[^>]+src=["']([^"']+)["']/i, 1]
        candidates << [0, from_html] if from_html.present?

        candidates.reject { |_score, url| !NewsSources::Image.usable?(url) }.max_by(&:first)&.last
      end

      def entry_title(entry)
        value = entry.title
        value.respond_to?(:content) ? value.content : value
      end

      def entry_link(entry)
        if entry.respond_to?(:link)
          link = entry.link
          return link.href if link.respond_to?(:href)
          return link if link.is_a?(String)
        end

        if entry.respond_to?(:links) && entry.links.present?
          alt = entry.links.find { |item| item.respond_to?(:rel) && item.rel.to_s == 'alternate' } || entry.links.first
          return alt.href if alt.respond_to?(:href)
        end

        entry.url if entry.respond_to?(:url)
      end

      def entry_content(entry)
        if entry.respond_to?(:content_encoded) && entry.content_encoded.present?
          return entry.content_encoded
        end
        if entry.respond_to?(:content) && entry.content.present?
          value = entry.content
          return value.respond_to?(:content) ? value.content : value
        end

        entry_summary(entry)
      end

      def entry_summary(entry)
        if entry.respond_to?(:description) && entry.description.present?
          return entry.description
        end
        if entry.respond_to?(:summary) && entry.summary.present?
          value = entry.summary
          return value.respond_to?(:content) ? value.content : value
        end

        ''
      end

      def entry_date(entry)
        raw = if entry.respond_to?(:pubDate) && entry.pubDate
                entry.pubDate
              elsif entry.respond_to?(:published) && entry.published
                entry.published
              elsif entry.respond_to?(:dc_date) && entry.dc_date
                entry.dc_date
              elsif entry.respond_to?(:updated) && entry.updated
                entry.updated
              elsif entry.respond_to?(:date) && entry.date
                entry.date
              end

        coerce_time(raw) || Time.current
      end

      def coerce_time(raw)
        return raw if raw.is_a?(Time)
        return raw.to_time if raw.respond_to?(:to_time)

        Time.zone.parse(raw.to_s)
      rescue ArgumentError, TypeError
        nil
      end

      def entry_author(entry)
        if entry.respond_to?(:author) && entry.author.present?
          return author_name(entry.author)
        end
        if entry.respond_to?(:dc_creator) && entry.dc_creator.present?
          return entry.dc_creator.to_s
        end

        ''
      end

      def author_name(value)
        value = value.first if value.is_a?(Array)
        raw = if value.respond_to?(:name) && value.name.present?
                value.name.to_s
              else
                value.to_s
              end
        named = raw[%r{<name>(.*?)</name>}i, 1]
        return named if named.present?

        ActionController::Base.helpers.strip_tags(raw).squish
      end

      def entry_image(entry)
        if entry.respond_to?(:enclosure) && entry.enclosure
          enc = entry.enclosure
          return enc.url if image_type?(enc.respond_to?(:type) ? enc.type : nil, enc.url)
        end

        media = media_url(entry)
        return media if media.present?

        raw = entry.to_s
        from_xml = raw[%r{media:(?:thumbnail|content)[^>]+url=["']([^"']+)["']}i, 1] ||
                   raw[%r{url=["']([^"']+)["'][^>]+media:(?:thumbnail|content)}i, 1] ||
                   raw[%r{itunes:image[^>]+href=["']([^"']+)["']}i, 1]
        return from_xml if from_xml.present?

        html = "#{entry_content(entry)} #{entry_summary(entry)}"
        html[/img[^>]+src=["']([^"']+)["']/i, 1]
      end

      def media_url(entry)
        if entry.respond_to?(:media_thumbnail) && entry.media_thumbnail.present?
          thumb = entry.media_thumbnail
          thumb = thumb.first if thumb.is_a?(Array)
          return thumb.url if thumb.respond_to?(:url)
        end
        if entry.respond_to?(:media_content) && entry.media_content.present?
          media = entry.media_content
          media = media.first if media.is_a?(Array)
          return media.url if media.respond_to?(:url)
        end

        nil
      end

      def image_type?(type, url)
        type.to_s.start_with?('image/') || url.to_s.match?(/\.(jpe?g|png|gif|webp|avif)(\?|$)/i)
      end
    end
  end
end
