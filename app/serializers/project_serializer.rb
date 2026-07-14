# frozen_string_literal: true

class ProjectSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :workspace_id, :archived, :archived_at,
             :created_at, :updated_at

  def archived
    object.archived?
  end
end
