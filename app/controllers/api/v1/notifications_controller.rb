# frozen_string_literal: true

module Api
  module V1
    # NotificationsController — list notifications and mark them as read.
    class NotificationsController < BaseController
      # GET /api/v1/notifications
      # Optional: ?unread=true
      def index
        notifications = current_user.notifications.order(created_at: :desc)
        notifications = notifications.unread if params[:unread].to_s == "true"

        records, meta = paginate(notifications)

        render_success(
          serialize_resource(records, serializer: NotificationSerializer),
          "Notifications retrieved",
          meta: meta
        )
      end

      # PATCH /api/v1/notifications/:id
      # Marks a single notification as read.
      def update
        notification = current_user.notifications.find(params[:id])
        notification.mark_as_read!

        render_success(
          serialize_resource(notification, serializer: NotificationSerializer),
          "Notification marked as read"
        )
      end

      # POST /api/v1/notifications/mark_all_read
      def mark_all_read
        current_user.notifications.unread.update_all(read: true)
        render_success(nil, "All notifications marked as read")
      end
    end
  end
end
