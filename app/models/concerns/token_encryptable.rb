# frozen_string_literal: true

# Encrypts OAuth tokens at rest using secret_key_base (not exposed to clients).
module TokenEncryptable
  extend ActiveSupport::Concern

  private

  def encrypt_secret(value)
    return if value.blank?

    message_encryptor.encrypt_and_sign(value.to_s)
  end

  def decrypt_secret(value)
    return if value.blank?

    message_encryptor.decrypt_and_verify(value.to_s)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage
    nil
  end

  def message_encryptor
    key = ActiveSupport::KeyGenerator
          .new(Rails.application.secret_key_base)
          .generate_key('youtube-oauth-tokens-v1', 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
end
