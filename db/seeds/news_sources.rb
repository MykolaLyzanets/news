# frozen_string_literal: true

# Official RSS/Atom feeds checked with HTTP 200. Cap: 30.
# Reuters, AP, CNBC, ESPN, CNN, and NYT have no stable public full text — skipped.

rows = [
  # World
  { name: 'BBC World', url: 'https://www.bbc.com/news/world', feed_url: 'https://feeds.bbci.co.uk/news/world/rss.xml', category: 'world', country: 'United Kingdom', priority: 10 },
  { name: 'The Guardian World', url: 'https://www.theguardian.com/world', feed_url: 'https://www.theguardian.com/world/rss', category: 'world', country: 'United Kingdom', priority: 20 },
  { name: 'Deutsche Welle World', url: 'https://www.dw.com', feed_url: 'https://rss.dw.com/xml/rss-en-world', category: 'world', country: 'Germany', priority: 30 },
  { name: 'CBS News World', url: 'https://www.cbsnews.com/world/', feed_url: 'https://www.cbsnews.com/latest/rss/world', category: 'world', country: 'United States', priority: 35 },
  { name: 'Al Jazeera', url: 'https://www.aljazeera.com', feed_url: 'https://www.aljazeera.com/xml/rss/all.xml', category: 'world', country: 'Qatar', priority: 40 },
  { name: 'NPR World', url: 'https://www.npr.org/sections/world/', feed_url: 'https://feeds.npr.org/1004/rss.xml', category: 'world', country: 'United States', priority: 45 },

  # Politics
  { name: 'BBC Politics', url: 'https://www.bbc.com/news/politics', feed_url: 'https://feeds.bbci.co.uk/news/politics/rss.xml', category: 'politics', country: 'United Kingdom', priority: 10 },
  { name: 'Politico', url: 'https://www.politico.com', feed_url: 'https://rss.politico.com/politics-news.xml', category: 'politics', country: 'United States', priority: 15 },
  { name: 'The Guardian Politics', url: 'https://www.theguardian.com/politics', feed_url: 'https://www.theguardian.com/politics/rss', category: 'politics', country: 'United Kingdom', priority: 20 },
  { name: 'ProPublica', url: 'https://www.propublica.org', feed_url: 'https://feeds.propublica.org/propublica/main', category: 'politics', country: 'United States', priority: 35 },
  { name: 'NPR Politics', url: 'https://www.npr.org/sections/politics/', feed_url: 'https://feeds.npr.org/1014/rss.xml', category: 'politics', country: 'United States', priority: 40 },

  # Business
  { name: 'BBC Business', url: 'https://www.bbc.com/news/business', feed_url: 'https://feeds.bbci.co.uk/news/business/rss.xml', category: 'business', country: 'United Kingdom', priority: 10 },
  { name: 'The Guardian Business', url: 'https://www.theguardian.com/business', feed_url: 'https://www.theguardian.com/business/rss', category: 'business', country: 'United Kingdom', priority: 20 },
  { name: 'NPR Business', url: 'https://www.npr.org/sections/business/', feed_url: 'https://feeds.npr.org/1006/rss.xml', category: 'business', country: 'United States', priority: 35 },

  # Technology
  { name: 'BBC Technology', url: 'https://www.bbc.com/news/technology', feed_url: 'https://feeds.bbci.co.uk/news/technology/rss.xml', category: 'technology', country: 'United Kingdom', priority: 10 },
  { name: 'The Verge', url: 'https://www.theverge.com', feed_url: 'https://www.theverge.com/rss/index.xml', category: 'technology', country: 'United States', parser_type: 'atom', priority: 25 },
  { name: 'TechCrunch', url: 'https://techcrunch.com', feed_url: 'https://techcrunch.com/feed/', category: 'technology', country: 'United States', priority: 30 },
  { name: 'Ars Technica', url: 'https://arstechnica.com', feed_url: 'https://feeds.arstechnica.com/arstechnica/index', category: 'technology', country: 'United States', priority: 40 },

  # Science
  { name: 'BBC Science', url: 'https://www.bbc.com/news/science_and_environment', feed_url: 'https://feeds.bbci.co.uk/news/science_and_environment/rss.xml', category: 'science', country: 'United Kingdom', priority: 10 },
  { name: 'The Guardian Science', url: 'https://www.theguardian.com/science', feed_url: 'https://www.theguardian.com/science/rss', category: 'science', country: 'United Kingdom', priority: 20 },
  { name: 'NPR Science', url: 'https://www.npr.org/sections/science/', feed_url: 'https://feeds.npr.org/1007/rss.xml', category: 'science', country: 'United States', priority: 35 },

  # Culture
  { name: 'BBC Culture', url: 'https://www.bbc.com/news/entertainment_and_arts', feed_url: 'https://feeds.bbci.co.uk/news/entertainment_and_arts/rss.xml', category: 'culture', country: 'United Kingdom', priority: 10 },
  { name: 'The Guardian Culture', url: 'https://www.theguardian.com/culture', feed_url: 'https://www.theguardian.com/culture/rss', category: 'culture', country: 'United Kingdom', priority: 20 },
  { name: 'NPR Arts', url: 'https://www.npr.org/sections/arts/', feed_url: 'https://feeds.npr.org/1008/rss.xml', category: 'culture', country: 'United States', priority: 35 },

  # Sport
  { name: 'BBC Sport', url: 'https://www.bbc.com/sport', feed_url: 'https://feeds.bbci.co.uk/sport/rss.xml', category: 'sport', country: 'United Kingdom', priority: 10 },
  { name: 'CBS Sports', url: 'https://www.cbssports.com', feed_url: 'https://www.cbssports.com/rss/headlines/', category: 'sport', country: 'United States', priority: 15 },
  { name: 'The Guardian Sport', url: 'https://www.theguardian.com/sport', feed_url: 'https://www.theguardian.com/sport/rss', category: 'sport', country: 'United Kingdom', priority: 20 },
  { name: 'Sky Sports', url: 'https://www.skysports.com', feed_url: 'https://www.skysports.com/rss/12040', category: 'sport', country: 'United Kingdom', priority: 25 },
  { name: 'BBC Football', url: 'https://www.bbc.com/sport/football', feed_url: 'https://feeds.bbci.co.uk/sport/football/rss.xml', category: 'sport', country: 'United Kingdom', priority: 35 },
  { name: 'The Guardian Football', url: 'https://www.theguardian.com/football', feed_url: 'https://www.theguardian.com/football/rss', category: 'sport', country: 'United Kingdom', priority: 40 }
]

keep = rows.map { |row| row[:feed_url] }

rows.each do |row|
  category = Category.find_by!(url: row[:category])
  source = Source.find_or_initialize_by(feed_url: row[:feed_url])
  source.assign_attributes(
    name: row[:name],
    url: row[:url],
    category:,
    country: row[:country],
    parser_type: row[:parser_type] || 'rss',
    language: 'en',
    active: true,
    priority: row[:priority]
  )
  source.save!
end

removed = Source.where.not(feed_url: keep)
puts "Removed: #{removed.ordered.pluck(:name).join(', ')}" if removed.exists?
removed.destroy_all

puts "Sources ready (#{Source.count}): #{Source.ordered.pluck(:name).join(', ')}"
