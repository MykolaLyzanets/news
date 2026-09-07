# frozen_string_literal: true

require 'digest'

module NewsSources
  class Normalize
    TRACKING = /\A(utm_|fbclid|gclid|mc_cid|mc_eid)/i

    def self.url(value, base: nil)
      raw = value.to_s.strip
      return '' if raw.blank?

      uri = URI.parse(base.present? ? URI.join(base, raw).to_s : raw)
      return '' unless uri.is_a?(URI::HTTP) && uri.host.present?

      uri.fragment = nil
      uri.host = uri.host.downcase
      uri.query = clean_query(uri.query)
      path = uri.path.to_s.sub(%r{/+\z}, '')
      uri.path = path.presence || '/'
      uri.to_s
    rescue URI::InvalidURIError
      raw
    end

    def self.title(value)
      ActionController::Base.helpers.strip_tags(value.to_s).squish
    end

    def self.text(value)
      ActionController::Base.helpers.strip_tags(value.to_s).squish
    end

    def self.fingerprint(title, content)
      key = [title.to_s.downcase.gsub(/[^a-z0-9\s]/, '').squish, text(content).downcase[0, 400]].join('|')
      return if key.blank? || key == '|'

      Digest::SHA256.hexdigest(key)
    end

    def self.clean_query(query)
      return if query.blank?

      pairs = URI.decode_www_form(query).reject { |key, _| key.to_s.match?(TRACKING) }
      pairs.any? ? URI.encode_www_form(pairs) : nil
    rescue ArgumentError
      query
    end
  end
end
