# frozen_string_literal: true

class NotificationSerializer < ActiveModel::Serializer
  attributes :id, :title, :body, :read, :created_at, :updated_at
end
