# frozen_string_literal: true

module NewsSources
  class Client
    class Error < StandardError; end
    class TimeoutError < Error; end
    class HttpError < Error; end
    class TooLargeError < Error; end

    USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36'
    TIMEOUT = 20
    OPEN_TIMEOUT = 8
    MAX_BYTES = 2 * 1024 * 1024
    MAX_REDIRECTS = 5
    RETRIES = 2

    def get(url)
      with_retry do
        follow(url, mode: :text)
      end
    end

    def get_html(url)
      with_retry do
        follow(url, mode: :html)
      end
    end

    def get_file(url)
      with_retry do
        follow(url, mode: :file)
      end
    end

    private

    def with_retry
      tries = 0
      begin
        yield
      rescue TimeoutError, HttpError => e
        tries += 1
        raise if tries > RETRIES || !retriable?(e)

        sleep(0.4 * (2**(tries - 1)))
        retry
      end
    end

    def retriable?(error)
      return true if error.is_a?(TimeoutError)
      return false unless error.is_a?(HttpError)

      code = error.message[/\d{3}/].to_i
      code >= 500 || code == 429
    end

    def follow(url, hops = 0, mode: :text)
      raise Error, 'Too many redirects' if hops > MAX_REDIRECTS

      response = request(url, mode:)
      if redirect?(response)
        location = response.headers['location'].to_s
        raise Error, 'Redirect without location' if location.blank?

        return follow(absolute(url, location), hops + 1, mode:)
      end

      raise HttpError, "HTTP #{response.status}" unless response.success?

      body = response.body.to_s
      limit = mode == :file ? MAX_BYTES + 1.megabyte : MAX_BYTES
      raise TooLargeError, "Response exceeds #{limit} bytes" if body.bytesize > limit

      mode == :file ? file_payload(url, response, body) : encode(body)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Timeout::Error => e
      raise TimeoutError, e.message
    end

    def request(url, mode: :text)
      Faraday.get(url) do |req|
        req.options.timeout = TIMEOUT
        req.options.open_timeout = OPEN_TIMEOUT
        req.headers['User-Agent'] = USER_AGENT
        req.headers['Accept-Language'] = 'en-US,en;q=0.9'
        req.headers['Accept'] = accept_for(mode)
        if (origin = origin_for(url))
          req.headers['Referer'] = origin
        end
      end
    end

    def accept_for(mode)
      case mode
      when :file
        'image/avif,image/webp,image/*,*/*;q=0.8'
      when :html
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      else
        'application/rss+xml, application/atom+xml, application/xml, text/xml, */*'
      end
    end

    def origin_for(url)
      uri = URI.parse(url.to_s)
      return unless uri.is_a?(URI::HTTP) && uri.host.present?

      "#{uri.scheme}://#{uri.host}/"
    rescue URI::InvalidURIError
      nil
    end

    def file_payload(url, response, body)
      type = response.headers['content-type'].to_s.split(';').first.to_s
      unless type.start_with?('image/') || url.match?(/\.(jpe?g|png|gif|webp|avif)(\?|$)/i)
        return
      end
      return if body.bytesize < 2_048 || body.bytesize > 3 * 1024 * 1024

      name = File.basename(URI.parse(url).path.to_s)
      name = 'image.jpg' if name.blank? || name == '/'
      { body:, type: type.presence || 'image/jpeg', name: }
    rescue URI::InvalidURIError
      { body:, type: 'image/jpeg', name: 'image.jpg' }
    end

    def redirect?(response)
      [301, 302, 303, 307, 308].include?(response.status)
    end

    def absolute(base, location)
      URI.join(base, location).to_s
    rescue URI::InvalidURIError
      location
    end

    def encode(body)
      body.force_encoding(Encoding::UTF_8)
      return body if body.valid_encoding?

      body.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '')
    end
  end
end
