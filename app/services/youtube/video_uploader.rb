# frozen_string_literal: true

require 'google/apis/youtube_v3'
require 'tempfile'
require 'open-uri'

module Youtube
  class VideoUploader
    Metadata = Data.define(:title, :description, :tags, :category_id, :privacy_status)

    def self.call(connection:, video_source:, metadata:)
      new(connection: connection, video_source: video_source, metadata: metadata).call
    end

    def initialize(connection:, video_source:, metadata:)
      @connection = connection
      @video_source = video_source
      @metadata = metadata
    end

    def call
      client = Client.new(connection: @connection)
      snippet = Google::Apis::YoutubeV3::VideoSnippet.new(
        title: @metadata.title,
        description: @metadata.description,
        tags: Array(@metadata.tags),
        category_id: @metadata.category_id
      )
      status = Google::Apis::YoutubeV3::VideoStatus.new(
        privacy_status: @metadata.privacy_status,
        self_declared_made_for_kids: false
      )
      video_object = Google::Apis::YoutubeV3::Video.new(snippet: snippet, status: status)

      result = nil
      with_tempfile do |path|
        result = client.service.insert_video(
          'snippet,status',
          video_object,
          upload_source: path,
          content_type: 'video/mp4'
        )
      end

      video_id = result&.id
      raise UploadError, 'YouTube did not return video id' if video_id.blank?

      {
        youtube_video_id: video_id,
        youtube_url: "https://www.youtube.com/watch?v=#{video_id}"
      }
    rescue Google::Apis::AuthorizationError => e
      @connection&.mark_invalid!(e.message)
      raise AuthError, e.message
    rescue Google::Apis::ClientError, Google::Apis::ServerError, Google::Apis::RateLimitError => e
      raise UploadError, ErrorTranslator.call(e)
    end

    private

    def with_tempfile
      Tempfile.create(['youtube_upload', '.mp4']) do |file|
        file.binmode
        URI.open(@video_source, open_timeout: 30, read_timeout: 600) do |remote|
          IO.copy_stream(remote, file)
        end
        file.flush
        file.rewind
        yield file.path
      end
    end
  end
end
