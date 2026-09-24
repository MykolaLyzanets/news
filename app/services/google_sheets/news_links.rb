# frozen_string_literal: true

module GoogleSheets
  class NewsLinks
    def append(post)
      return unless Config.configured?

      client.append(range, [row_for(post)])
    end

    def sync_all!
      return unless Config.configured?

      posts = Post.visible.order(:date, :id)
      rows = posts.map { |post| row_for(post) }
      client.clear_range(range)
      return if rows.empty?

      client.update(range, rows)
    end

    private

    def client
      @client ||= Client.new
    end

    def range
      "'#{Config.sheet_name}'!A:B"
    end

    def row_for(post)
      [format_datetime(post.date), article_url(post)]
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
