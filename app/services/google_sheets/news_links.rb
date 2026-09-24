# frozen_string_literal: true

module GoogleSheets
  class NewsLinks
    def append(post)
      return unless Config.configured?

      client.append_rows!([row_for(post)])
    end

    def sync_all!
      return unless Config.configured?

      rows = Post.visible.order(:date, :id).map { |post| row_for(post) }
      client.clear_sheet_data!
      client.write_rows!(rows)
    end

    private

    def client
      @client ||= Client.new
    end

    def row_for(post)
      [format_datetime(post.date || post.created_at), article_url(post)]
    end

    def format_datetime(time)
      time = time.in_time_zone if time.respond_to?(:in_time_zone)
      time.strftime('%Y-%m-%d %H:%M:%S')
    end

    def article_url(post)
      "#{site_origin}/articles/#{post.to_param}"
    end

    def site_origin
      ENV.fetch('SITEMAP_HOST', 'https://lyzfol.com')
    end
  end
end
