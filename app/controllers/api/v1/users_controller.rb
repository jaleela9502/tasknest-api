# frozen_string_literal: true

module Api
  module V1
    # UsersController manages the current user's profile and avatar.
    class UsersController < BaseController
      # GET /api/v1/profile
      def show
        render_success(
          serialize_resource(current_user, serializer: UserSerializer),
          "Profile retrieved"
        )
      end

      # PATCH /api/v1/profile
      # Body: { name, email, password, password_confirmation }
      def update
        if current_user.update(profile_params)
          render_success(
            serialize_resource(current_user, serializer: UserSerializer),
            "Profile updated"
          )
        else
          render_error("Profile update failed", current_user.errors.full_messages)
        end
      end

      # POST /api/v1/profile/avatar
      # Multipart form: avatar=<file>
      def upload_avatar
        unless params[:avatar].present?
          return render_error("Avatar file is required")
        end

        current_user.avatar.attach(params[:avatar])

        if current_user.avatar.attached?
          render_success(
            serialize_resource(current_user, serializer: UserSerializer),
            "Avatar uploaded"
          )
        else
          render_error("Avatar upload failed")
        end
      end

      private

      def profile_params
        params.permit(:name, :email, :password, :password_confirmation)
      end
    end
  end
end
