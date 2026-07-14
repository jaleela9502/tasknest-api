# frozen_string_literal: true

# Attachment wraps an uploaded file for a Task using Active Storage.
class Attachment < ApplicationRecord
  belongs_to :task
  belongs_to :user

  has_one_attached :file

  validate :file_must_be_attached

  private

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end
