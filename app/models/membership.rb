# frozen_string_literal: true

# Membership links a User to a Workspace and stores their role.
class Membership < ApplicationRecord
  ROLES = %w[owner admin member].freeze

  belongs_to :user
  belongs_to :workspace

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :workspace_id, message: "is already a member of this workspace" }

  def owner?
    role == "owner"
  end

  def admin?
    role == "admin" || owner?
  end
end
