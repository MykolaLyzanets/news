# frozen_string_literal: true

module Internal
  module Autoria
    class YoutubeUploadsController < ActionController::API
      before_action :verify_signature!

      def create
        payload = JSON.parse(request.raw_post)
        connection = resolve_connection(payload)
        unless connection&.connected?
          return render json: { error: 'YouTube connection not found or not connected on news' }, status: :unprocessable_entity
        end

        sync_connection_metadata!(connection, payload)

        upload = AutoriaYoutubeUpload.create!(
          job_id: payload.fetch('job_id'),
          autoria_vehicle_video_id: payload.fetch('vehicle_video_id'),
          autoria_youtube_connection_id: payload.fetch('youtube_connection_id'),
          youtube_connection: connection,
          video_url: payload.fetch('video_url'),
          title: payload.fetch('title'),
          description: payload['description'],
          tags: Array(payload['tags']),
          privacy_status: payload.fetch('privacy_status'),
          category_id: payload.fetch('category_id'),
          callback_url: payload.fetch('callback_url'),
          status: 'pending'
        )

        ::Autoria::ProcessYoutubeUploadJob.perform_later(upload.id)
        render json: { job_id: upload.job_id, status: 'accepted' }, status: :accepted
      rescue ActiveRecord::RecordNotUnique
        render json: { error: 'duplicate job_id' }, status: :conflict
      rescue KeyError => e
        render json: { error: "missing field: #{e.key}" }, status: :bad_request
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end

      private

      def verify_signature!
        body = request.raw_post
        signature = request.headers['X-Autoria-Signature']
        ::Autoria::ApiSecret.verify!(body, signature)
      end

      def resolve_connection(payload)
        channel_id = payload['youtube_channel_id'].to_s.presence
        autoria_connection_id = payload['youtube_connection_id']

        YoutubeConnection.active.find_by(autoria_youtube_connection_id: autoria_connection_id) ||
          (channel_id.present? ? YoutubeConnection.active.find_by(channel_id: channel_id) : nil)
      end

      def sync_connection_metadata!(connection, payload)
        attrs = {}
        labels = Array(payload['brand_labels']).map(&:to_s).map(&:strip).reject(&:blank?)
        attrs[:brand_labels] = labels.join(', ') if labels.any?

        title = payload['autoria_channel_title'].to_s.strip
        attrs[:autoria_channel_title] = title if title.present?

        connection.update!(attrs) if attrs.present?
      end
    end
  end
end
