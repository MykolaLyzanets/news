# frozen_string_literal: true

module NewsSources
  module Parsers
    class Base
      def initialize(body, source:)
        @body = body
        @source = source
      end

      def items
        raise NotImplementedError
      end
    end
  end
end
