# frozen_string_literal: true

module Autoria
  class ProcessYoutubeUploadJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 0

    MAX_POLL_ATTEMPTS = 20

    def perform(upload_id, poll_attempt = 0)
      upload = AutoriaYoutubeUpload.find_by(id: upload_id)
      return if upload.blank?

      if poll_attempt.zero?
        run_upload!(upload)
        return
      end

      poll_processing!(upload, poll_attempt)
    end

    private

    def run_upload!(upload)
      connection = upload.youtube_connection
      unless connection&.connected?
        fail_upload!(upload, 'YouTube channel is not connected on news')
        return
      end

      upload.mark!('downloading')
      metadata = Youtube::VideoUploader::Metadata.new(
        title: upload.title,
        description: upload.description.to_s,
        tags: upload.tags,
        category_id: upload.category_id,
        privacy_status: upload.privacy_status
      )

      upload.mark!('uploading')
      result = Youtube::VideoUploader.call(
        connection: connection,
        video_source: upload.video_url,
        metadata: metadata
      )

      upload.mark!('processing', youtube_video_id: result[:youtube_video_id])
      CallbackClient.notify!(upload, status: 'processing', youtube_video_id: result[:youtube_video_id])
      self.class.set(wait: 30.seconds).perform_later(upload.id, 1)
    rescue Youtube::AuthError, Youtube::UploadError, Youtube::Error => e
      fail_upload!(upload, e.message)
    rescue StandardError => e
      fail_upload!(upload, "#{e.class}: #{e.message}")
      raise
    end

    def poll_processing!(upload, attempt)
      connection = upload.youtube_connection
      return fail_upload!(upload, 'Missing YouTube connection') if connection.blank?
      return fail_upload!(upload, 'Missing youtube_video_id') if upload.youtube_video_id.blank?

      client = Youtube::Client.new(connection: connection)
      status = client.video_processing_status(upload.youtube_video_id)
      decision = Youtube::PublishDecision.call(status, expected_privacy: upload.privacy_status)

      if decision.failed?
        fail_upload!(upload, decision.message)
        return
      end

      if decision.published?
        upload.mark!('published')
        CallbackClient.notify!(upload, status: 'published', youtube_video_id: upload.youtube_video_id)
        return
      end

      if attempt >= MAX_POLL_ATTEMPTS
        fail_upload!(upload, 'YouTube processing timeout')
        return
      end

      wait = [30 * attempt, 300].min.seconds
      upload.update!(poll_attempts: attempt)
      self.class.set(wait: wait).perform_later(upload.id, attempt + 1)
    rescue Youtube::AuthError, Youtube::Error => e
      fail_upload!(upload, e.message)
    end

    def fail_upload!(upload, message)
      upload.mark!('failed', error_message: message.to_s.truncate(2000))
      CallbackClient.notify!(upload, status: 'failed', error: message)
    end
  end
end
