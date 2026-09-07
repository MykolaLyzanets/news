# frozen_string_literal: true

module AdminHelper
  def admin_posts_q(overrides = {})
    query = { category: params[:category], live: params[:live], page: params[:page] }
      .merge(overrides)
    query[:page] = nil if query[:page].to_i <= 1
    query.compact_blank
  end

  def admin_tab_on?(on)
    on ? 'admin__tab is-on' : 'admin__tab'
  end

  def admin_pill_on?(on)
    on ? 'admin__pill is-on' : 'admin__pill'
  end

  def admin_page_list(page, pages)
    return [1] if pages <= 1

    ids = [1, pages]
    ((page - 2)..(page + 2)).each { |n| ids << n if n.between?(1, pages) }
    ids.uniq.sort
  end

  def admin_source_name(source, linked: true)
    return unless source

    name = if linked && source.url.present?
             link_to source.name, source.url, target: '_blank', rel: 'noopener', class: 'admin__list-name'
           else
             content_tag(:span, source.name, class: 'admin__list-name')
           end
    country = (content_tag(:span, source.country, class: 'admin__country') if source.country.present?)
    content_tag(:span, safe_join([name, country].compact), class: 'admin__source')
  end
end
