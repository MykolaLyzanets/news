# frozen_string_literal: true

class Topic < ApplicationRecord
  has_many :event_topics, dependent: :destroy
  has_many :events, through: :event_topics
  has_many :posts, through: :events

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :name, uniqueness: true

  before_validation :fill_slug

  JUNK_SLUG = /
    \A(
      getty(?:-images)?|bbc|reuters|afp|pa-media|cnn|npr|
      monday|tuesday|wednesday|thursday|friday|saturday|sunday|
      according-to|speaking-.*|if-.*|male-staff|female-staff
    )\z
  /x

  def to_param
    slug
  end

  def self.upsert_named!(names)
    Array(names).map { |item| item.to_s.squish }.compact_blank.uniq
               .select { |name| usable_name?(name) }.first(6).filter_map do |name|
      find_or_create_by!(slug: name.parameterize) do |topic|
        topic.name = name
      end
    rescue ActiveRecord::RecordNotUnique
      find_by(slug: name.parameterize)
    end
  end

  def self.usable_name?(name)
    slug = name.to_s.parameterize
    return false if slug.blank? || slug.length < 4
    return false if JUNK_SLUG.match?(slug)
    return false if name.split.size == 1 && name.length < 4

    true
  end

  private

  def fill_slug
    self.slug = name.to_s.parameterize if slug.blank?
  end
end
