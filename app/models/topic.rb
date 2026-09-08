# frozen_string_literal: true

class Topic < ApplicationRecord
  has_many :event_topics, dependent: :destroy
  has_many :events, through: :event_topics
  has_many :posts, through: :events

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :name, uniqueness: true

  before_validation :fill_slug

  def to_param
    slug
  end

  def self.upsert_named!(names)
    Array(names).map { |item| item.to_s.squish }.compact_blank.uniq.first(12).map do |name|
      find_or_create_by!(slug: name.parameterize.presence || SecureRandom.hex(4)) do |topic|
        topic.name = name
      end
    rescue ActiveRecord::RecordNotUnique
      find_by!(slug: name.parameterize)
    end
  end

  private

  def fill_slug
    self.slug = name.to_s.parameterize if slug.blank?
  end
end
