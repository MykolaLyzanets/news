# frozen_string_literal: true

module NewsSources
  class Image
    JUNK = /pixel|tracking|spacer|1x1|transparent\.gif/i
    MIN_BYTES = 2_048

    def self.usable?(url)
      url.present? && !url.to_s.match?(JUNK)
    end

    def initialize(client: Client.new)
      @client = client
    end

    def pick(rss_url, page_url)
      return enlarge(rss_url) if self.class.usable?(rss_url)

      discover(page_url)
    end

    def attach(post, url)
      url = enlarge(url)
      return unless self.class.usable?(url)

      post.update_column(:source_image_url, url) if post.source_image_url.blank? || !self.class.usable?(post.source_image_url)
      return if post.image.present? && real_file?(post)

      file = @client.get_file(url)
      return unless file && file[:body].bytesize >= MIN_BYTES

      tmp = tempfile_for(file)
      post.image = tmp
      post.save!
    rescue StandardError => e
      Rails.logger.warn("[NewsSource] Image skip: #{e.message}")
    ensure
      cleanup(tmp)
    end

    def discover(page_url)
      html = @client.get_html(page_url)
      doc = Nokogiri::HTML(html)
      %w[og:image og:image:secure_url twitter:image twitter:image:src].each do |name|
        content = doc.at_css("meta[property='#{name}'], meta[name='#{name}']")&.[]('content')
        found = Normalize.url(content, base: page_url)
        return enlarge(found) if self.class.usable?(found)
      end
      nil
    rescue StandardError => e
      Rails.logger.warn("[NewsSource] Image discover skip: #{e.message}")
      nil
    end

    def enlarge(url)
      return url if url.blank?

      url.to_s.sub(%r{/ace/standard/\d+/}, '/ace/standard/976/')
    end

    private

    def real_file?(post)
      path = post.image.path
      path.present? && File.exist?(path) && File.size(path) >= MIN_BYTES
    rescue StandardError
      false
    end

    def tempfile_for(file)
      ext = File.extname(file[:name].to_s)
      ext = '.jpg' if ext.blank? || ext == '.'
      tmp = Tempfile.new(['post-image', ext])
      tmp.binmode
      tmp.write(file[:body])
      tmp.rewind
      tmp
    end

    def cleanup(tmp)
      return unless tmp

      tmp.close
      tmp.unlink
    rescue StandardError
      nil
    end
  end
end
