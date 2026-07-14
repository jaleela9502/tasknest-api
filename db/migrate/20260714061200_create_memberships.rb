# frozen_string_literal: true

class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workspace, null: false, foreign_key: true
      # Roles: owner, admin, member
      t.string :role, null: false, default: "member"

      t.timestamps
    end

    # A user can only be a member of a workspace once
    add_index :memberships, [ :user_id, :workspace_id ], unique: true
  end
end
