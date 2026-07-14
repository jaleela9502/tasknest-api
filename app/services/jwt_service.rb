# frozen_string_literal: true

# JwtService creates and verifies JSON Web Tokens.
# Keep this class small and easy to read — no fancy patterns.
#
# Note: we use ::JWT (with leading ::) so Ruby looks up the top-level
# jwt gem module, not a nested JwtService::JWT constant.
class JwtService
  # Algorithm used to sign tokens
  ALGORITHM = "HS256"

  # How long a token stays valid
  EXPIRATION_TIME = 24.hours

  # Encodes a payload into a JWT string.
  # Always adds exp (expiry) and jti (unique token id for logout).
  def self.encode(user_id)
    payload = {
      user_id: user_id,
      exp: EXPIRATION_TIME.from_now.to_i,
      jti: SecureRandom.uuid
    }

    ::JWT.encode(payload, secret_key, ALGORITHM)
  end

  # Decodes a JWT string back into a Hash.
  # Returns nil if the token is invalid, expired, or blacklisted.
  def self.decode(token)
    return nil if token.blank?

    decoded_payload = ::JWT.decode(token, secret_key, true, { algorithm: ALGORITHM }).first

    # Reject tokens that were logged out
    return nil if TokenBlacklist.blacklisted?(decoded_payload["jti"])

    decoded_payload
  rescue ::JWT::DecodeError, ::JWT::ExpiredSignature
    nil
  end

  def self.secret_key
    Rails.application.secret_key_base
  end
end
