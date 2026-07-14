# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :created_at, :updated_at, :avatar_url

  def avatar_url
    return nil unless object.avatar.attached?

    Rails.application.routes.url_helpers.rails_blob_url(object.avatar, only_path: true)
  end
end
