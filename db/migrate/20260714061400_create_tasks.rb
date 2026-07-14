# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      # Status: todo, in_progress, review, done
      t.string :status, null: false, default: "todo"
      # Priority: low, medium, high
      t.string :priority, null: false, default: "medium"
      t.date :due_date
      # Optional assignee — who should do this task
      t.references :assignee, null: true, foreign_key: { to_table: :users }
      # Who created the task
      t.references :creator, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tasks, :status
    add_index :tasks, :priority
    add_index :tasks, :due_date
  end
end
