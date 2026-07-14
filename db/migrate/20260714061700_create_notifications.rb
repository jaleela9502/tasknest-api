# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      # false = unread, true = read
      t.boolean :read, null: false, default: false

      t.timestamps
    end

    add_index :notifications, :read
  end
end
