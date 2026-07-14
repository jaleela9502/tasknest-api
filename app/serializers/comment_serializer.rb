# frozen_string_literal: true

class CommentSerializer < ActiveModel::Serializer
  attributes :id, :body, :task_id, :user_id, :created_at, :updated_at, :user

  def user
    {
      id: object.user.id,
      name: object.user.name,
      email: object.user.email
    }
  end
end
