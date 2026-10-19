# frozen_string_literal: true

require 'faraday'
require 'json'

module Autoria
  class CallbackClient
    def self.notify!(upload, status:, youtube_video_id: nil, error: nil)
      new(upload).notify!(status: status, youtube_video_id: youtube_video_id, error: error)
    end

    def initialize(upload)
      @upload = upload
    end

    def notify!(status:, youtube_video_id: nil, error: nil)
      payload = {
        job_id: @upload.job_id,
        vehicle_video_id: @upload.autoria_vehicle_video_id,
        youtube_connection_id: @upload.autoria_youtube_connection_id,
        status: status.to_s,
        youtube_video_id: youtube_video_id,
        error: error
      }.compact

      body = JSON.generate(payload)
      response = Faraday.post(@upload.callback_url) do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['X-Autoria-Signature'] = ApiSecret.sign(body)
        req.body = body
        req.options.open_timeout = 15
        req.options.timeout = 30
      end

      return if response.success?

      Rails.logger.error(
        "[Autoria::CallbackClient] callback failed upload=#{@upload.id} http=#{response.status} body=#{response.body.to_s.truncate(500)}"
      )
    end
  end
end
