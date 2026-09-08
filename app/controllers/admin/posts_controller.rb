# frozen_string_literal: true

module Admin
  class PostsController < BaseController
    before_action :set_post, only: %i[edit update destroy rewrite publish hide regenerate]

    PER_PAGE = 20

    def index
      @categories = Category.ordered
      @category = @categories.find { |item| item.url == params[:category] }

      scope = Post.includes(:category, :source).newest
      scope = scope.where(category_id: @category.id) if @category
      scope = apply_live(scope)

      @counts = apply_live(Post.all).group(:category_id).count
      @count_all = @counts.values.sum
      @per_page = PER_PAGE
      @total = scope.count
      @pages = [(@total.to_f / @per_page).ceil, 1].max
      @page = [[params[:page].to_i, 1].max, @pages].min
      @posts = scope.offset((@page - 1) * @per_page).limit(@per_page)
    end

    def edit; end

    def update
      going_live = publish_requested? && !@post.published?
      attrs = going_live ? post_params.except(:published) : post_params
      unless @post.update(attrs)
        render :edit, status: :unprocessable_entity
        return
      end

      if going_live && (block = NewsDesk::Quota.claim_publication!(@post.reload)).is_a?(Symbol)
        redirect_to edit_admin_post_path(@post), alert: NewsDesk::Quota.message(block)
        return
      end

      redirect_to admin_posts_path, notice: 'Post saved'
    end

    def destroy
      @post.destroy
      back_to_posts 'Post deleted'
    end

    def rewrite
      result = Posts::RewriteService.new(@post).call
      if result[:ok]
        redirect_to edit_admin_post_path(@post), notice: 'AI changed title'
      else
        redirect_to edit_admin_post_path(@post), alert: result[:error]
      end
    end

    def rewrite_all
      Posts::RewriteAllJob.perform_later
      back_to_posts 'AI rewrite queued for new posts'
    end

    def regenerate
      unless @post.event
        redirect_to edit_admin_post_path(@post), alert: 'Post has no event'
        return
      end

      post = NewsDesk::Publish.new.regenerate(@post.event)
      if post.is_a?(Post)
        redirect_to edit_admin_post_path(@post), notice: 'Article regenerated from event facts'
      else
        redirect_to edit_admin_post_path(@post), alert: @post.event.reload.ai_error.presence || 'Regenerate failed'
      end
    end

    def publish
      result = NewsDesk::Quota.claim_publication!(@post)
      if result.is_a?(Symbol)
        redirect_back fallback_location: admin_posts_path, alert: NewsDesk::Quota.message(result)
      else
        back_to_posts 'Post is live'
      end
    end

    def hide
      @post.update!(published: false)
      back_to_posts 'Post is hidden'
    end

    private

    def publish_requested?
      ActiveModel::Type::Boolean.new.cast(post_params[:published])
    end

    def apply_live(scope)
      return scope.where(published: true) if params[:live] == '1'
      return scope.where(published: false) if params[:live] == '0'

      scope
    end

    def back_to_posts(notice)
      redirect_back fallback_location: admin_posts_path, notice: notice
    end

    def set_post
      @post = Post.find_by(url: params[:id]) || Post.find(params[:id])
    end

    def post_params
      params.require(:post).permit(
        :category_id, :title, :intro, :text, :label, :note, :quote, :quote_name,
        :published, :main, :breaking, :special, :minutes, :image
      )
    end
  end
end
