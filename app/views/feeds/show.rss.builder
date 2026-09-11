xml.instruct!
xml.rss version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom' do
  xml.channel do
    xml.title 'Lyzfol'
    xml.link root_url
    xml.description 'Latest news from Lyzfol covering world, politics, business, technology, science, culture and sport.'
    xml.language 'en'
    xml.tag! 'atom:link', href: feed_url, rel: 'self', type: 'application/rss+xml'
    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.link article_url(post)
        xml.guid article_url(post)
        xml.pubDate post.date&.httpdate
        xml.description post.excerpt(40)
        xml.category post.category.name
      end
    end
  end
end
