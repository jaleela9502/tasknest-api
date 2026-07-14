# frozen_string_literal: true

class MembershipSerializer < ActiveModel::Serializer
  attributes :id, :role, :user_id, :workspace_id, :created_at, :updated_at, :user

  def user
    {
      id: object.user.id,
      name: object.user.name,
      email: object.user.email
    }
  end
end
