# frozen_string_literal: true

module Admin
  class SourcesController < BaseController
    before_action :set_source, only: %i[edit update destroy fetch test toggle parse]

    def index
      @sources = Source.ordered.includes(:category)
    end

    def new
      @source = Source.new(parser_type: 'rss', language: 'en', priority: 10, active: true)
    end

    def edit; end

    def create
      @source = Source.new(source_params)
      if @source.save
        redirect_to admin_sources_path, notice: 'Source saved'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @source.update(source_params)
        redirect_to admin_sources_path, notice: 'Source saved'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @source.destroy
      redirect_to admin_sources_path, notice: 'Source deleted'
    end

    def fetch
      NewsSources::FetchJob.perform_later(@source.id)
      redirect_to admin_sources_path, notice: "Fetch queued for #{@source.name}"
    end

    def fetch_all
      NewsDesk::CycleJob.perform_later
      redirect_to admin_sources_path, notice: 'Desk cycle queued: fetch, cluster, and publish within the daily cap'
    end

    def parse
      fetch
    end

    def parse_all
      fetch_all
    end

    def test
      result = NewsSources::TestSource.new(@source).call
      if result[:ok]
        redirect_to admin_sources_path,
                    notice: "Connection: OK. Items found: #{result[:fetched]}. Latest item: #{result[:latest]}"
      else
        redirect_to admin_sources_path, alert: result[:error]
      end
    end

    def toggle
      @source.update!(active: !@source.active?)
      redirect_back fallback_location: admin_sources_path,
                    notice: @source.active? ? 'Source is active' : 'Source is inactive'
    end

    private

    def set_source
      @source = Source.find(params[:id])
    end

    def source_params
      params.require(:source).permit(
        :name, :url, :feed_url, :category_id, :parser_type, :language, :country, :active, :priority
      )
    end
  end
end
