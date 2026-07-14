# frozen_string_literal: true

# User represents a person who can log into TaskNest.
# Passwords are hashed with bcrypt via has_secure_password.
class User < ApplicationRecord
  has_secure_password

  # Profile picture stored with Active Storage
  has_one_attached :avatar

  has_many :owned_workspaces, class_name: "Workspace", foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner
  has_many :memberships, dependent: :destroy
  has_many :workspaces, through: :memberships
  has_many :created_tasks, class_name: "Task", foreign_key: :creator_id, dependent: :destroy, inverse_of: :creator
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, dependent: :nullify, inverse_of: :assignee
  has_many :comments, dependent: :destroy
  has_many :attachments, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  before_validation :normalize_email

  # Builds a short-lived reset token, stores a digest, and returns the raw token
  # so the caller can "send" it (we log it in development for learning).
  def generate_password_reset_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update!(
      reset_password_token: Digest::SHA256.hexdigest(raw_token),
      reset_password_sent_at: Time.current
    )
    raw_token
  end

  # Finds a user by the raw reset token if it is still valid (2 hours).
  def self.find_by_valid_reset_token(raw_token)
    return nil if raw_token.blank?

    digested_token = Digest::SHA256.hexdigest(raw_token)
    user = find_by(reset_password_token: digested_token)
    return nil if user.nil?
    return nil if user.reset_password_sent_at.nil?
    return nil if user.reset_password_sent_at < 2.hours.ago

    user
  end

  def clear_password_reset_token!
    update!(reset_password_token: nil, reset_password_sent_at: nil)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
