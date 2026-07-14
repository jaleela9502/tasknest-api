# frozen_string_literal: true

# Attachments store metadata; the actual file lives in Active Storage.
class CreateAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :attachments do |t|
      t.references :task, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :filename

      t.timestamps
    end
  end
end
