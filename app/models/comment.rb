# frozen_string_literal: true

# A Comment is a message left on a Task by a User.
class Comment < ApplicationRecord
  belongs_to :task
  belongs_to :user

  validates :body, presence: true
end
