# frozen_string_literal: true

class TaskSerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :status, :priority, :due_date,
             :project_id, :assignee_id, :creator_id, :created_at, :updated_at,
             :assignee, :creator

  def assignee
    return nil unless object.assignee

    {
      id: object.assignee.id,
      name: object.assignee.name,
      email: object.assignee.email
    }
  end

  def creator
    {
      id: object.creator.id,
      name: object.creator.name,
      email: object.creator.email
    }
  end
end
