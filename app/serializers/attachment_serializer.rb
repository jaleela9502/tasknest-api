# frozen_string_literal: true

class AttachmentSerializer < ActiveModel::Serializer
  attributes :id, :filename, :task_id, :user_id, :created_at, :updated_at, :download_url

  def download_url
    return nil unless object.file.attached?

    "/api/v1/attachments/#{object.id}/download"
  end
end
