# frozen_string_literal: true

module NewsSources
  class TestSource
    def initialize(source, client: Client.new)
      @source = source
      @client = client
    end

    def call
      unless @source.fetchable?
        return { ok: false, error: "Parser #{@source.parser_type} is not implemented yet" }
      end

      body = @client.get(@source.feed_url)
      items = Parser.build(@source, body).items
      latest = items.first
      {
        ok: true,
        fetched: items.size,
        latest: latest&.title
      }
    rescue StandardError => e
      { ok: false, error: e.message }
    end
  end
end
