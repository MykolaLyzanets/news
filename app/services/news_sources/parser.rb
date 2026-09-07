# frozen_string_literal: true

module NewsSources
  class Parser
    MAP = {
      'rss' => Parsers::Rss,
      'atom' => Parsers::Rss
    }.freeze

    def self.build(source, body)
      klass = MAP[source.parser_type]
      raise Client::Error, "Parser #{source.parser_type} is not implemented yet" unless klass

      klass.new(body, source:)
    end
  end
end
