# frozen_string_literal: true

module ApplicationHelper
  SECTION_NAV = [
    ['Home', 'home'],
    ['World', 'world'],
    ['Politics', 'politics'],
    ['Business', 'business'],
    ['Technology', 'technology'],
    ['Science', 'science'],
    ['Culture', 'culture'],
    ['Sport', 'sport']
  ].freeze

  def section_nav
    SECTION_NAV
  end

  def current_section
    return params[:section] if controller_name == 'categories'
    return @post.category.url if controller_name == 'articles' && @post
    return 'home' if controller_name == 'articles'

    'home'
  end

  def section_href(id)
    id == 'home' ? root_path : section_path(id)
  end

  def breaking_post
    @breaking_post ||= Post.visible.fresh.urgent.newest.first
  end

  def story_time(post)
    return '' unless post&.date

    minutes = ((Time.current - post.date) / 60).to_i
    return "#{minutes}m ago" if minutes < 60
    return "#{minutes / 60}h ago" if minutes < 1_440

    post.date.strftime('%b %-d')
  end

  def post_image_tag(post, **opts)
    opts = opts.reverse_merge(alt: post.title)
    if post.image.present?
      image_tag post.image.url, **opts
    elsif post.source_image_url.present?
      image_tag post.source_image_url, opts.merge(onerror: 'this.remove()')
    end
  end

  def page_title
    if controller_name == 'articles' && @post
      return "#{@post.title} — THE DISPATCH"
    end
    return 'THE DISPATCH' if current_section == 'home'

    "#{current_section.to_s.titleize} — THE DISPATCH"
  end
end
