# frozen_string_literal: true

# Seed data for local development and learning.
# Run with: bin/rails db:seed

# Only seed development (keeps the test database clean for RSpec)
unless Rails.env.development?
  puts "Skipping seeds (not development)."
  return
end

puts "Seeding TaskNest..."

# Clear existing data so seeds can be re-run safely
Notification.delete_all
Attachment.destroy_all
Comment.delete_all
Task.delete_all
Project.delete_all
Membership.delete_all
Workspace.delete_all
TokenBlacklist.delete_all
User.destroy_all

owner = User.create!(
  name: "Alice Owner",
  email: "alice@tasknest.com",
  password: "password",
  password_confirmation: "password"
)

member = User.create!(
  name: "Bob Member",
  email: "bob@tasknest.com",
  password: "password",
  password_confirmation: "password"
)

admin = User.create!(
  name: "Carol Admin",
  email: "carol@tasknest.com",
  password: "password",
  password_confirmation: "password"
)

puts "Created users: alice@tasknest.com, bob@tasknest.com, carol@tasknest.com (password: password)"

# ---------------------------------------------------------------
# Workspace + members
# ---------------------------------------------------------------
workspace = owner.owned_workspaces.create!(
  name: "Acme Product Team",
  description: "Sample workspace for TaskNest demos"
)

# Owner membership is created automatically by Workspace#after_create
workspace.memberships.create!(user: admin, role: "admin")
workspace.memberships.create!(user: member, role: "member")

puts "Created workspace: #{workspace.name}"

# ---------------------------------------------------------------
# Projects + tasks
# ---------------------------------------------------------------
project = workspace.projects.create!(
  name: "Website Redesign",
  description: "Public marketing site refresh"
)

Task.create!(
  project: project,
  creator: owner,
  assignee: member,
  title: "Draft homepage wireframes",
  description: "Create low-fidelity wireframes for the new homepage.",
  status: "in_progress",
  priority: "high",
  due_date: Date.current + 3
)

Task.create!(
  project: project,
  creator: owner,
  assignee: admin,
  title: "Write landing page copy",
  description: "Draft headlines and CTAs for the landing page.",
  status: "todo",
  priority: "medium",
  due_date: Date.current + 7
)

Task.create!(
  project: project,
  creator: admin,
  assignee: member,
  title: "Fix footer links",
  description: "Update outdated links in the site footer.",
  status: "done",
  priority: "low",
  due_date: Date.current - 2
)

Task.create!(
  project: project,
  creator: owner,
  assignee: member,
  title: "Overdue logo updates",
  description: "This task is intentionally overdue for dashboard demos.",
  status: "todo",
  priority: "high",
  due_date: Date.current - 5
)

puts "Created project and sample tasks"

# ---------------------------------------------------------------
# Comments + notifications
# ---------------------------------------------------------------
first_task = project.tasks.first

Comment.create!(
  task: first_task,
  user: owner,
  body: "Looking good so far — keep going!"
)

Notification.create!(
  user: member,
  title: "Welcome to TaskNest",
  body: "You have been added to the Acme Product Team workspace.",
  read: false
)

puts "Seed complete!"
