# frozen_string_literal: true

class RelaxPostsSourceUrlUniqueness < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      UPDATE posts SET source_url = NULL WHERE source_url = '';
    SQL

    remove_index :posts, :source_url
    add_index :posts, :source_url,
              unique: true,
              where: 'source_url IS NOT NULL AND manual = false',
              name: 'index_posts_on_source_url_dedupe'
  end

  def down
    remove_index :posts, name: 'index_posts_on_source_url_dedupe'
    add_index :posts, :source_url, unique: true
  end
end
