# frozen_string_literal: true

module NewsSources
  class Fetch
    def initialize(source, client: Client.new, importer: Import.new, dedup: Dedup.new)
      @source = source
      @client = client
      @importer = importer
      @dedup = dedup
    end

    def call
      log('Fetch started')
      @source.mark_fetched!

      return result(ok: false, error: 'Source is inactive') unless @source.active?

      unless @source.fetchable?
        error = "Parser #{@source.parser_type} is not implemented yet"
        @source.mark_error!(error)
        return result(ok: false, error:)
      end

      body = @client.get(@source.feed_url)
      items = Parser.build(@source, body).items.select { |item| Post.fresh?(item.published_at) }
                    .first(NewsDesk::Config.item_limit)
      added = 0
      duplicates = 0

      items.each do |item|
        if @dedup.duplicate?(item)
          fill_image(item)
          duplicates += 1
          next
        end

        if @importer.call(item)
          added += 1
        else
          fill_image(item)
          duplicates += 1
        end
      end

      @source.mark_success!
      log("Fetched: #{items.size} New: #{added} Duplicates: #{duplicates}")
      result(ok: true, fetched: items.size, added:, duplicates:)
    rescue StandardError => e
      @source.mark_error!(e.message)
      Rails.logger.error("[NewsSource] #{@source.name} Error: #{e.class} #{e.message}")
      result(ok: false, error: e.message)
    end

    private

    def fill_image(item)
      url = Normalize.url(item.source_url)
      article = SourceArticle.find_by(source_url: [item.source_url, url].uniq) ||
                Post.find_by(source_url: [item.source_url, url].uniq)
      return unless article && !article.photo?

      images = Image.new
      image_url = images.pick(item.image_url, article.source_url)
      images.attach(article, image_url)
    end

    def log(message)
      Rails.logger.info("[NewsSource] #{@source.name} #{message}")
    end

    def result(ok:, fetched: 0, added: 0, duplicates: 0, error: nil)
      { ok:, fetched:, added:, duplicates:, error: }
    end
  end
end
