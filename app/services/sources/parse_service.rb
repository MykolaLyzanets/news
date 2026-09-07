# frozen_string_literal: true

module Sources
  class ParseService
    def initialize(source)
      @source = source
    end

    def call
      NewsSources::Fetch.new(@source).call
    end
  end
end
