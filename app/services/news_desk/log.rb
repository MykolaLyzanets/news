# frozen_string_literal: true

module NewsDesk
  class Log
    def self.info(message, event: nil, source: nil, post: nil, operation: nil)
      Rails.logger.info(format(message, event:, source:, post:, operation:))
    end

    def self.error(message, event: nil, source: nil, post: nil, operation: nil)
      Rails.logger.error(format(message, event:, source:, post:, operation:))
    end

    def self.format(message, event:, source:, post:, operation:)
      [
        '[NewsDesk]',
        ("[event_id=#{event.id}]" if event),
        ("[source_id=#{source.id}]" if source),
        ("[post_id=#{post.id}]" if post),
        ("[#{operation}]" if operation),
        message
      ].compact.join(' ')
    end
  end
end
