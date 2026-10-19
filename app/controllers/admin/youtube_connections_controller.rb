# frozen_string_literal: true

module Admin
  class YoutubeConnectionsController < BaseController
    def index
      @connections = YoutubeConnection.order(
        Arel.sql("COALESCE(brand_labels, '')"),
        :channel_title,
        :id
      )
    end

    def update
      connection = YoutubeConnection.find(params[:id])
      if connection.update(connection_params)
        redirect_to admin_youtube_connections_path, notice: 'Збережено'
      else
        redirect_to admin_youtube_connections_path, alert: connection.errors.full_messages.to_sentence
      end
    end

    private

    def connection_params
      params.require(:youtube_connection).permit(:autoria_youtube_connection_id, :brand_labels)
    end
  end
end
