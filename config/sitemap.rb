# frozen_string_literal: true

SitemapGenerator::Sitemap.default_host = ENV.fetch('SITEMAP_HOST', 'https://lyzfol.com')
SitemapGenerator::Sitemap.compress = false
SitemapGenerator::Sitemap.create_index = false
SitemapGenerator::Sitemap.include_root = false

SitemapGenerator::Sitemap.create do
  add root_path, changefreq: 'hourly', priority: 1.0, lastmod: Post.visible.maximum(:updated_at)
  add privacy_path, changefreq: 'yearly', priority: 0.3
  add terms_path, changefreq: 'yearly', priority: 0.3

  CategoriesController::SECTIONS.each do |section|
    category = Category.find_by(url: section)
    lastmod = category&.posts&.visible&.maximum(:updated_at)
    add section_path(section: section), changefreq: 'hourly', priority: 0.8, lastmod: lastmod
  end

  topic_ids = Topic.joins(:posts).merge(Post.visible).distinct.pluck(:id)
  Topic.where(id: topic_ids).find_each do |topic|
    add topic_path(id: topic.to_param),
        changefreq: 'daily',
        priority: 0.6,
        lastmod: topic.posts.visible.maximum(:updated_at)
  end

  Post.visible.find_each do |post|
    add article_path(id: post.to_param), changefreq: 'daily', priority: 0.7, lastmod: post.updated_at
  end
end
