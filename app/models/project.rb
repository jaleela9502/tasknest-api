# frozen_string_literal: true

# A Project belongs to a Workspace and contains many Tasks.
# Soft-archive with archived_at instead of deleting.
class Project < ApplicationRecord
  belongs_to :workspace
  has_many :tasks, dependent: :destroy

  validates :name, presence: true

  # Default scope helpers — prefer scopes over default_scope for beginners.
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def restore!
    update!(archived_at: nil)
  end
end
