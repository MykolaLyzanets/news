# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :posts, dependent: :restrict_with_error
  has_many :sources, dependent: :restrict_with_error
  has_many :events, dependent: :restrict_with_error
  has_many :source_articles, dependent: :restrict_with_error

  validates :name, presence: true
  validates :url, presence: true, uniqueness: true
  validates :sort, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :fill_url

  scope :ordered, -> { order(:sort, :name) }

  def to_param
    url
  end

  private

  def fill_url
    self.url = name.to_s.parameterize if url.blank?
  end
end
