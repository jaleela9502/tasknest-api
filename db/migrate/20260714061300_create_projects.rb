# frozen_string_literal: true

class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      # When set, the project is archived (hidden from active lists)
      t.datetime :archived_at

      t.timestamps
    end

    add_index :projects, :archived_at
  end
end
