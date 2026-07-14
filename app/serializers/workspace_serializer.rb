# frozen_string_literal: true

class WorkspaceSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :owner_id, :created_at, :updated_at
end
