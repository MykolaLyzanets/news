# frozen_string_literal: true

module ApplicationHelper
  SITE_NAME = 'Lyzfol'
  SITE_ORIGIN = ENV.fetch('SITEMAP_HOST', 'https://lyzfol.com')

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
    return @post.category.url if article_page?

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
    return unless post.real_image?

    opts = opts.reverse_merge(alt: post.title, loading: 'lazy', decoding: 'async')
    image_tag post.image.url, **opts
  end

  def page_meta_tags
    image = page_share_image
    tags = {
      title: page_title,
      description: page_description,
      canonical: canonical_url,
      viewport: 'width=device-width, initial-scale=1',
      icon: [
        { href: '/favicon.ico', type: 'image/x-icon' },
        { href: '/favicon.png', type: 'image/png', sizes: '32x32' },
        { href: '/apple-touch-icon.png', rel: 'apple-touch-icon', sizes: '180x180', type: 'image/png' }
      ],
      og: {
        title: :title,
        description: :description,
        type: article_page? ? 'article' : 'website',
        url: canonical_url,
        site_name: SITE_NAME,
        locale: 'en_GB'
      },
      twitter: {
        card: image.present? ? 'summary_large_image' : 'summary',
        title: :title,
        description: :description
      }
    }
    if image.present?
      tags[:og][:image] = image
      tags[:twitter][:image] = image
    end
    if article_page?
      tags[:article] = {
        published_time: @post.date&.iso8601,
        modified_time: @post.updated_at&.iso8601,
        section: @post.category.name
      }
    end
    tags[:robots] = 'noindex, follow' if noindex_page?
    tags
  end

  def page_title
    return 'Page not found | Lyzfol' if not_found_page?
    return "#{@post.category.name}: #{@post.title}" if article_page?
    return "#{@topic.name} | Lyzfol" if topic_page?
    if controller_name == 'pages'
      return 'Privacy Policy | Lyzfol' if action_name == 'privacy'
      return 'Terms and Conditions | Lyzfol' if action_name == 'terms'
    end
    if controller_name == 'categories'
      base = "#{category_seo_name} News, Trends & Expert Insights"
      return @page.to_i > 1 ? "#{base} — Page #{@page}" : base
    end

    'Latest News, Business Insights & Expert Articles'
  end

  def page_description
    return 'The page you requested is not available on Lyzfol.' if not_found_page?
    return @post.meta_description if article_page?
    return "Lyzfol coverage related to #{@topic.name}." if topic_page?
    if controller_name == 'pages' && action_name == 'privacy'
      return 'How Lyzfol collects, uses and protects personal information when you read news on lyzfol.com.'
    end
    if controller_name == 'pages' && action_name == 'terms'
      return 'Terms and conditions for using Lyzfol, including news content, acceptable use, intellectual property and liability limits.'
    end
    if controller_name == 'categories'
      return "Explore the latest #{category_seo_name.downcase} news, industry trends, expert insights and practical analysis covering the topics, companies and developments that matter."
    end

    'Discover the latest news, expert insights, industry trends and practical perspectives across business, technology, finance, marketing and more.'
  end

  def article_page?
    controller_name == 'articles' && @post.present?
  end

  def topic_page?
    controller_name == 'topics' && @topic.present?
  end

  def category_seo_name
    @category&.name.presence || current_section.to_s.titleize
  end

  def canonical_url
    return root_url if not_found_page?

    url = "#{canonical_origin}#{canonical_path}"
    url += "?page=#{@page}" if category_paginated?
    url
  end

  def page_jsonld
    graph = [organization_schema, website_schema]
    graph << news_article_schema(@post) if article_page?
    graph << breadcrumb_schema if breadcrumbs.present?
    { '@context' => 'https://schema.org', '@graph' => graph }.to_json
  end

  def breadcrumbs
    return [] if not_found_page?

    crumbs = [{ name: 'Home', url: root_url }]
    if article_page?
      crumbs << { name: @post.category.name, url: section_url(@post.category.url) }
      crumbs << { name: @post.title, url: canonical_url }
    elsif controller_name == 'categories' && @section.present?
      crumbs << { name: category_seo_name, url: canonical_url }
    elsif topic_page?
      crumbs << { name: @topic.name, url: canonical_url }
    elsif controller_name == 'pages' && action_name == 'privacy'
      crumbs << { name: 'Privacy Policy', url: canonical_url }
    elsif controller_name == 'pages' && action_name == 'terms'
      crumbs << { name: 'Terms and Conditions', url: canonical_url }
    else
      return []
    end
    crumbs
  end

  def source_credits_links(post)
    links = post.source_credits.map do |credit|
      if credit[:url].present?
        link_to(credit[:name], credit[:url], rel: 'nofollow noopener noreferrer', target: '_blank')
      else
        credit[:name]
      end
    end
    safe_join(links, ', ')
  end

  private

  def noindex_page?
    @noindex.present? || topic_page? || not_found_page?
  end

  def not_found_page?
    @not_found.present? || action_name == 'not_found'
  end

  def category_paginated?
    controller_name == 'categories' && @page.to_i > 1
  end

  def canonical_origin
    return SITE_ORIGIN if Rails.env.production?

    request.base_url
  end

  def canonical_path
    path = request.path.chomp('/')
    path.presence || '/'
  end

  def page_share_image
    if article_page?
      jsonld_image(@post)
    elsif controller_name == 'home' && @lead
      jsonld_image(@lead)
    elsif controller_name == 'categories' && @lead_post
      jsonld_image(@lead_post)
    end
  end

  def jsonld_image(post)
    return unless post&.real_image?

    url = post.image.url.to_s
    url.start_with?('http') ? url : "#{canonical_origin}#{url}"
  end

  def publisher_schema
    {
      '@type' => 'Organization',
      '@id' => "#{SITE_ORIGIN}/#organization",
      'name' => SITE_NAME,
      'url' => root_url,
      'logo' => {
        '@type' => 'ImageObject',
        'url' => "#{SITE_ORIGIN}/apple-touch-icon.png",
        'width' => 180,
        'height' => 180
      }
    }
  end

  def organization_schema
    publisher_schema
  end

  def website_schema
    {
      '@type' => 'WebSite',
      '@id' => "#{SITE_ORIGIN}/#website",
      'name' => SITE_NAME,
      'url' => root_url,
      'inLanguage' => 'en',
      'publisher' => { '@id' => "#{SITE_ORIGIN}/#organization" }
    }
  end

  def news_article_schema(post)
    data = {
      '@type' => 'NewsArticle',
      'headline' => post.title,
      'description' => post.meta_description,
      'datePublished' => post.date&.iso8601,
      'dateModified' => post.updated_at&.iso8601,
      'inLanguage' => 'en',
      'articleSection' => post.category.name,
      'mainEntityOfPage' => canonical_url,
      'author' => { '@id' => "#{SITE_ORIGIN}/#organization" },
      'publisher' => { '@id' => "#{SITE_ORIGIN}/#organization" }
    }
    image = jsonld_image(post)
    data['image'] = image if image.present?
    data
  end

  def breadcrumb_schema
    {
      '@type' => 'BreadcrumbList',
      'itemListElement' => breadcrumbs.each_with_index.map do |crumb, index|
        {
          '@type' => 'ListItem',
          'position' => index + 1,
          'name' => crumb[:name],
          'item' => crumb[:url]
        }
      end
    }
  end
end
