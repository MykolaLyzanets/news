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

    def attach(record, url, referer: nil)
      url = enlarge(url)
      return unless self.class.usable?(url)

      assign_source_url(record, url)
      return if real_file?(record)

      file = @client.get_file(url, referer: referer.presence || record.try(:source_url))
      return unless file && file[:body].bytesize >= MIN_BYTES

      tmp = tempfile_for(file)
      prepared = prepare_for_upload(tmp)
      record.image = prepared
      record.save!
    rescue StandardError => e
      Rails.logger.warn("[NewsSource] Image skip: #{e.message}")
    ensure
      cleanup(tmp)
      cleanup(prepared) if prepared && prepared != tmp
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

    def assign_source_url(record, url)
      return if record.source_image_url.present? && self.class.usable?(record.source_image_url)

      if record.persisted?
        record.update_column(:source_image_url, url)
      else
        record.source_image_url = url
      end
    end

    def real_file?(record)
      path = record.image.path
      path.present? && File.exist?(path) && File.size(path) >= MIN_BYTES
    rescue StandardError
      false
    end

    def tempfile_for(file)
      ext = File.extname(file[:name].to_s)
      ext = '.jpg' if ext.blank? || ext == '.'
      tmp = Tempfile.new(['source-image', ext])
      tmp.binmode
      tmp.write(file[:body])
      tmp.rewind
      tmp
    end

    def prepare_for_upload(tmp)
      img = MiniMagick::Image.open(tmp.path)
      img.auto_orient
      img.resize '1600x1600>'
      img.format 'jpg'
      img.quality 85
      out = Tempfile.new(['post-image', '.jpg'])
      out.binmode
      img.write(out.path)
      out.rewind
      out
    rescue StandardError => e
      Rails.logger.warn("[NewsSource] Image resize skip: #{e.message}")
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
