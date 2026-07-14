# frozen_string_literal: true

class CreateWorkspaces < ActiveRecord::Migration[8.1]
  def change
    create_table :workspaces do |t|
      t.string :name, null: false
      t.text :description
      # The user who created / owns this workspace
      t.references :owner, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
