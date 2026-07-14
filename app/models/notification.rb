# frozen_string_literal: true

# Simple in-app notification for a User.
class Notification < ApplicationRecord
  belongs_to :user

  validates :title, presence: true

  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }

  def mark_as_read!
    update!(read: true)
  end
end
