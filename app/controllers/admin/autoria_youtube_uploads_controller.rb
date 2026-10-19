# frozen_string_literal: true

module Admin
  class AutoriaYoutubeUploadsController < BaseController
    PER_PAGE = 25

    def index
      scope = AutoriaYoutubeUpload.includes(:youtube_connection).recent
      scope = apply_status_filter(scope)

      @status_counts = AutoriaYoutubeUpload.group(:status).count
      @total_in_progress = AutoriaYoutubeUpload.in_progress.count
      @per_page = PER_PAGE
      @total = scope.count
      @pages = [(@total.to_f / @per_page).ceil, 1].max
      @page = [[params[:page].to_i, 1].max, @pages].min
      @uploads = scope.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def show
      @upload = AutoriaYoutubeUpload.includes(:youtube_connection).find(params[:id])
    end

    private

    def apply_status_filter(scope)
      case params[:status]
      when 'in_progress'
        scope.in_progress
      when 'published', 'failed'
        scope.where(status: params[:status])
      else
        scope
      end
    end
  end
end
