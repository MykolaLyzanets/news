# frozen_string_literal: true

module NewsSources
  class Item
    ATTRS = %i[title content summary source_url image_url published_at author source].freeze

    attr_reader(*ATTRS)

    def initialize(**attrs)
      ATTRS.each { |key| instance_variable_set(:"@#{key}", attrs[key]) }
    end

    def to_h
      ATTRS.index_with { |key| public_send(key) }
    end
  end
end
