# frozen_string_literal: true

# Helps create simple in-app notifications without complex callbacks.
class NotificationService
  def self.notify(user:, title:, body: nil)
    return if user.nil?

    Notification.create!(
      user: user,
      title: title,
      body: body
    )
  end
end
