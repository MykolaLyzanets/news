# frozen_string_literal: true

# News seed data goes here.

admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@gmail.com')
admin_password = ENV.fetch('ADMIN_PASSWORD', 'admin@gmail.com')

User.find_or_create_by!(email: admin_email) do |user|
  user.password = admin_password
  user.password_confirmation = admin_password
  user.admin = true
end

puts "Admin user ready: #{admin_email}"

[
  { name: 'World', url: 'world', label: 'World Desk', text: 'News from other countries.', sort: 1 },
  { name: 'Politics', url: 'politics', label: 'Politics Desk', text: 'News about government and laws.', sort: 2 },
  { name: 'Business', url: 'business', label: 'Business Desk', text: 'News about money, trade, and companies.', sort: 3 },
  { name: 'Technology', url: 'technology', label: 'Investigative Section Desk', text: 'In-depth reporting, investigative scoops, and rigorous analysis on artificial intelligence, hardware supply chains, cyber warfare, and Silicon Valley regulation.', sort: 4 },
  { name: 'Science', url: 'science', label: 'Science Desk', text: 'News about science, health, and the planet.', sort: 5 },
  { name: 'Culture', url: 'culture', label: 'Culture Desk', text: 'News about books, film, music, and art.', sort: 6 },
  { name: 'Sport', url: 'sport', label: 'Sport Desk', text: 'News about football, tennis, and other games.', sort: 7 }
].each do |row|
  Category.find_or_initialize_by(url: row[:url]).update!(row)
end

puts "Categories ready: #{Category.ordered.pluck(:name).join(', ')}"

load Rails.root.join('db/seeds/news_sources.rb')
