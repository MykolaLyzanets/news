# frozen_string_literal: true

module Admin
  class EventsController < BaseController
    before_action :set_event, only: %i[show publish hide regenerate merge split ignore]

    PER_PAGE = 20

    def index
      scope = Event.includes(:category, :post, :source_articles).order(score: :desc, id: :desc)
      scope = scope.where(status: params[:status]) if params[:status].present?
      @per_page = PER_PAGE
      @total = scope.count
      @pages = [(@total.to_f / @per_page).ceil, 1].max
      @page = params[:page].to_i.clamp(1, @pages)
      @events = scope.offset((@page - 1) * @per_page).limit(@per_page)
      @counts = Event.group(:status).count
    end

    def show
      @articles = @event.source_articles.includes(:source)
      @others = Event.where.not(id: @event.id).order(id: :desc).limit(40)
    end

    def publish
      if @event.post
        result = NewsDesk::Quota.claim_publication!(@event.post)
        if result.is_a?(Symbol)
          redirect_to admin_event_path(@event), alert: NewsDesk::Quota.message(result)
        else
          redirect_to admin_event_path(@event), notice: 'Event published'
        end
      else
        post = NewsDesk::Publish.new.regenerate(@event)
        if post.is_a?(Post)
          redirect_to admin_event_path(@event), notice: 'Event published'
        else
          redirect_to admin_event_path(@event),
                      alert: @event.reload.ai_error.presence || 'Publish skipped (quota or quality)'
        end
      end
    end

    def hide
      @event.post&.update!(published: false)
      @event.update!(status: 'ignored')
      redirect_to admin_events_path, notice: 'Event hidden'
    end

    def regenerate
      post = NewsDesk::Publish.new.regenerate(@event)
      if post.is_a?(Post)
        redirect_to admin_event_path(@event), notice: 'Article regenerated'
      else
        redirect_to admin_event_path(@event), alert: @event.reload.ai_error.presence || 'Regenerate failed'
      end
    end

    def merge
      other = Event.find(params[:other_id])
      @event.absorb!(other)
      redirect_to admin_event_path(@event), notice: "Merged event ##{other.id}"
    rescue StandardError => e
      redirect_to admin_event_path(@event), alert: e.message
    end

    def split
      child = @event.split!(Array(params[:article_ids]))
      if child
        redirect_to admin_event_path(child), notice: 'Event split'
      else
        redirect_to admin_event_path(@event), alert: 'Select source articles to split'
      end
    end

    def ignore
      @event.update!(status: 'ignored')
      redirect_to admin_events_path, notice: 'Event ignored'
    end

    private

    def set_event
      @event = Event.find(params[:id])
    end
  end
end
