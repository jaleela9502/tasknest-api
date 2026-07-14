# frozen_string_literal: true

# Stores JWT IDs that have been logged out so those tokens stop working.
class TokenBlacklist < ApplicationRecord
  validates :jti, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def self.blacklisted?(jti)
    exists?(jti: jti)
  end

  # Remove expired blacklist rows (optional cleanup helper).
  def self.cleanup_expired!
    where("expires_at < ?", Time.current).delete_all
  end
end
