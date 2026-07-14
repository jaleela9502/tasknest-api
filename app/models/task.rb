# frozen_string_literal: true

# A Task is a unit of work inside a Project.
class Task < ApplicationRecord
  STATUSES = %w[todo in_progress review done].freeze
  PRIORITIES = %w[low medium high].freeze

  belongs_to :project
  belongs_to :creator, class_name: "User", inverse_of: :created_tasks
  belongs_to :assignee, class_name: "User", optional: true, inverse_of: :assigned_tasks

  has_many :comments, dependent: :destroy
  has_many :attachments, dependent: :destroy

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }

  scope :completed, -> { where(status: "done") }
  scope :pending, -> { where.not(status: "done") }
  # Overdue = due date in the past AND not done yet
  scope :overdue, -> { pending.where("due_date < ?", Date.current) }

  # Simple search by title or description
  scope :search, ->(query) {
    return all if query.blank?

    where("title ILIKE :q OR description ILIKE :q", q: "%#{query}%")
  }

  scope :filter_by_status, ->(status) {
    return all if status.blank?

    where(status: status)
  }

  scope :filter_by_priority, ->(priority) {
    return all if priority.blank?

    where(priority: priority)
  }

  scope :filter_by_assignee, ->(assignee_id) {
    return all if assignee_id.blank?

    where(assignee_id: assignee_id)
  }

  # Whitelist column names allowed for sorting (prevents SQL injection).
  ALLOWED_SORT_COLUMNS = %w[title status priority due_date created_at updated_at].freeze

  def self.sorted_by(sort_column, sort_direction)
    column = ALLOWED_SORT_COLUMNS.include?(sort_column) ? sort_column : "created_at"
    direction = sort_direction.to_s.downcase == "asc" ? "ASC" : "DESC"
    order("#{column} #{direction}")
  end
end
