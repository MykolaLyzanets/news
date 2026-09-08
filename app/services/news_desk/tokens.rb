# frozen_string_literal: true

require 'set'

module NewsDesk
  class Tokens
    STOP = %w[
      the a an and or of to in on for with by from at as is was are were be
      after before over new says say said its their his her about into than
      more that this those these will not not into up down out off
    ].freeze

    MONTHS = %w[
      january february march april may june july august september october
      november december jan feb mar apr jun jul aug sep sept oct nov dec
    ].freeze

    def self.normalized_title(title)
      title.to_s.downcase.gsub(/[^a-z0-9\s]/, ' ').split - STOP
    end

    def self.match_key(title)
      normalized_title(title).first(8).sort.join(' ')
    end

    def self.entities(title, text = nil)
      hay = "#{title} #{text.to_s.truncate(900)}"
      {
        'keywords' => normalized_title(title),
        'names' => hay.scan(/(?:[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)/).uniq.first(12),
        'numbers' => hay.scan(/\b\d+(?:[.,]\d+)?\b/).uniq.first(8),
        'dates' => dates_in(hay)
      }
    end

    def self.cheap_score(left, right)
      left_tokens = Set.new(normalized_title(left[:title]))
      right_tokens = Set.new(normalized_title(right[:title]))
      return 0.0 if left_tokens.empty? || right_tokens.empty?

      jaccard = (left_tokens & right_tokens).size.to_f / (left_tokens | right_tokens).size
      names = overlap(left.dig(:entities, 'names'), right.dig(:entities, 'names'))
      numbers = overlap(left.dig(:entities, 'numbers'), right.dig(:entities, 'numbers'))
      dates = overlap(left.dig(:entities, 'dates'), right.dig(:entities, 'dates'))
      category = left[:category_id] == right[:category_id] ? 0.08 : 0.0
      [jaccard + (names * 0.14) + (numbers * 0.1) + (dates * 0.08) + category, 1.0].min
    end

    def self.overlap(left, right)
      a = Array(left).map { |item| item.to_s.downcase }
      b = Array(right).map { |item| item.to_s.downcase }
      return 0.0 if a.empty? || b.empty?

      (a & b).size.to_f / (a | b).size
    end

    def self.dates_in(text)
      found = text.scan(/\b\d{1,2}\s+(?:#{MONTHS.join('|')})\s+\d{4}\b/i)
      found += text.scan(/\b(?:#{MONTHS.join('|')})\s+\d{1,2},?\s+\d{4}\b/i)
      found += text.scan(/\b\d{4}-\d{2}-\d{2}\b/)
      found.map(&:downcase).uniq.first(6)
    end
  end
end
