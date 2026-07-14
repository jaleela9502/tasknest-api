# frozen_string_literal: true

# A Workspace is a shared space that holds projects and members.
class Workspace < ApplicationRecord
  belongs_to :owner, class_name: "User", inverse_of: :owned_workspaces

  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :projects, dependent: :destroy

  validates :name, presence: true

  # After creating a workspace, automatically add the owner as a member with role "owner".
  after_create :add_owner_as_member

  private

  def add_owner_as_member
    memberships.create!(user: owner, role: "owner")
  end
end
