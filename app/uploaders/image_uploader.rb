# frozen_string_literal: true

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  process :to_webp

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_allowlist
    %w[jpg jpeg gif png webp avif]
  end

  def size_range
    1..(3.megabytes)
  end

  def filename
    'photo.webp'
  end

  private

  def to_webp
    manipulate! do |img|
      img.format('webp')
      img.quality(82)
      img
    end
  end
end
