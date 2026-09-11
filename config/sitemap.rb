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

  Post.visible.find_each do |post|
    options = { changefreq: 'daily', priority: 0.7, lastmod: post.updated_at }
    if post.date.present? && post.date >= 2.days.ago
      options[:news] = {
        publication_name: 'Lyzfol',
        publication_language: 'en',
        title: post.title,
        publication_date: post.date
      }
    end
    add article_path(id: post.to_param), options
  end
end
