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
    return @post.category.url if article_page?
    return 'home' if controller_name == 'articles'
    return 'home' if controller_name == 'topics'

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

  def display_readers(post)
    2_000 + ((post.id * 7_919) % 7_001)
  end

  def post_image_tag(post, **opts)
    opts = opts.reverse_merge(alt: post.title)
    if post.image.present?
      image_tag post.image.url, **opts
    elsif post.source_image_url.present?
      image_tag post.source_image_url, opts.merge(onerror: 'this.remove()')
    end
  end

  def page_meta_tags
    tags = {
      title: page_title,
      description: page_description,
      canonical: canonical_url,
      viewport: 'width=device-width, initial-scale=1',
      og: {
        title: :title,
        description: :description,
        type: article_page? ? 'article' : 'website',
        url: canonical_url
      }
    }
    image = article_page? ? jsonld_image(@post) : nil
    tags[:og][:image] = image if image.present?
    tags
  end

  def page_title
    if article_page?
      return "#{@post.category.name}: #{@post.title}"
    end
    if topic_page?
      return "#{@topic.name} — THE DISPATCH"
    end
    return 'Latest News, Business Insights & Expert Articles' if current_section == 'home'
    if controller_name == 'categories'
      return "#{category_seo_name} News, Trends & Expert Insights"
    end

    "#{current_section.to_s.titleize} — THE DISPATCH"
  end

  def page_description
    if article_page?
      return @post.meta_description
    end
    if topic_page?
      return "Coverage of #{@topic.name} from THE DISPATCH."
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
    "#{request.base_url}#{request.path}"
  end

  def news_article_jsonld(post)
    data = {
      '@context' => 'https://schema.org',
      '@type' => 'NewsArticle',
      'headline' => post.title,
      'description' => post.meta_description,
      'datePublished' => post.date&.iso8601,
      'dateModified' => post.updated_at&.iso8601,
      'mainEntityOfPage' => article_url(post),
      'author' => { '@type' => 'Organization', 'name' => 'THE DISPATCH' },
      'publisher' => { '@type' => 'Organization', 'name' => 'THE DISPATCH' }
    }
    image = jsonld_image(post)
    data['image'] = image if image.present?
    data.to_json
  end

  def jsonld_image(post)
    if post.real_image?
      url = post.image.url.to_s
      url.start_with?('http') ? url : "#{request.base_url}#{url}"
    else
      post.source_image_url.presence
    end
  end
end
