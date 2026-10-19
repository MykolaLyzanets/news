# frozen_string_literal: true

module Youtube
  # Decides whether a videos.list status is published, failed, or still waiting.
  class PublishDecision
    TERMINAL_UPLOAD = %w[failed rejected terminated deleted].freeze
    TERMINAL_PROCESSING = %w[failed terminated].freeze
    IN_PROGRESS_PROCESSING = %w[processing].freeze
    NOT_FOUND = 'Video not found'

    attr_reader :outcome, :message

    def self.call(status, expected_privacy: 'public')
      new(status, expected_privacy: expected_privacy).tap(&:evaluate)
    end

    def initialize(status, expected_privacy:)
      @status = status || {}
      @expected_privacy = expected_privacy.to_s.downcase.presence
      @outcome = :waiting
      @message = nil
      @clear_video_id = false
    end

    def evaluate
      if not_found?
        @outcome = :waiting
        return self
      end

      if terminal_failure?
        @outcome = :failed
        @message = ErrorTranslator.call(failure.presence || processing.presence || upload.presence || 'processingFailed')
        @clear_video_id = true
        return self
      end

      unless publishable?
        @outcome = :waiting
        return self
      end

      if privacy.blank?
        @outcome = :waiting
        return self
      end

      if privacy_mismatch?
        @outcome = :failed
        @message = I18n.t(
          'youtube.errors.forced_private_by_youtube',
          expected: @expected_privacy,
          actual: privacy
        )
        @clear_video_id = false
        return self
      end

      @outcome = :published
      self
    end

    def published?
      @outcome == :published
    end

    def failed?
      @outcome == :failed
    end

    def waiting?
      @outcome == :waiting
    end

    def clear_video_id?
      @clear_video_id
    end

    def not_found?
      failure == NOT_FOUND
    end

    private

    def processing
      @status[:processing_status].to_s.downcase
    end

    def upload
      @status[:upload_status].to_s.downcase
    end

    def failure
      @status[:failure].to_s.presence
    end

    def privacy
      @status[:privacy_status].to_s.downcase
    end

    def details_present?
      @status[:processing_details_present] == true
    end

    def terminal_failure?
      TERMINAL_PROCESSING.include?(processing) ||
        TERMINAL_UPLOAD.include?(upload) ||
        (failure.present? && failure != NOT_FOUND)
    end

    def publishable?
      return true if processing == 'succeeded'
      return false if details_present?
      return false unless upload == 'processed'
      return false if IN_PROGRESS_PROCESSING.include?(processing)
      return false if TERMINAL_PROCESSING.include?(processing)
      return false if failure.present?

      true
    end

    def privacy_mismatch?
      return false if @expected_privacy.blank?

      privacy != @expected_privacy
    end
  end
end
