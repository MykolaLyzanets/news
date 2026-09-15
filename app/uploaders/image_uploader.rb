# frozen_string_literal: true

class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  process :to_webp, if: :magick_available?

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
    magick_available? ? 'photo.webp' : "photo#{File.extname(original_filename.to_s).presence || '.jpg'}"
  end

  private

  def magick_available?(*)
    self.class.magick_available?
  end

  def self.magick_available?
    return @magick_available if defined?(@magick_available)

    @magick_available = begin
      MiniMagick.cli
      MiniMagick.cli_version
      true
    rescue StandardError
      false
    end
  end

  def to_webp
    manipulate! do |img|
      img.format('webp')
      img.quality(82)
      img
    end
  end
end
