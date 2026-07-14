# frozen_string_literal: true

module Api
  module V1
    # BaseController is the parent class for all API v1 controllers.
    # It provides:
    # - JSON response helpers
    # - JWT authentication helpers
    # - Simple pagination helper
    # - Global error handling
    class BaseController < ApplicationController
      before_action :authenticate_user!

      rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

      private

      # ---------------------------------------------------------------
      # Authentication
      # ---------------------------------------------------------------

      # Reads the Bearer token from the Authorization header and finds the user.
      def authenticate_user!
        header = request.headers["Authorization"]
        token = header.to_s.split(" ").last

        payload = JwtService.decode(token)
        if payload.nil?
          return render_error("Unauthorized. Please log in.", nil, status: :unauthorized)
        end

        @current_user = User.find_by(id: payload["user_id"])
        if @current_user.nil?
          render_error("Unauthorized. User not found.", nil, status: :unauthorized)
        end
      end

      def current_user
        @current_user
      end

      # Checks that the current user belongs to the given workspace.
      def require_workspace_member!(workspace)
        membership = workspace.memberships.find_by(user: current_user)
        return membership if membership

        render_error("You are not a member of this workspace.", nil, status: :forbidden)
        nil
      end

      # Checks that the current user is an admin or owner of the workspace.
      def require_workspace_admin!(workspace)
        membership = require_workspace_member!(workspace)
        return nil if membership.nil?

        return membership if membership.admin?

        render_error("You must be an admin or owner to do this.", nil, status: :forbidden)
        nil
      end

      # ---------------------------------------------------------------
      # JSON helpers
      # ---------------------------------------------------------------

      def render_success(data = nil, message = "Success", status: :ok, meta: nil)
        response_body = {
          success: true,
          message: message,
          data: data
        }
        response_body[:meta] = meta if meta.present?

        render json: response_body, status: status
      end

      def render_error(message = "Error", errors = nil, status: :unprocessable_content)
        render json: {
          success: false,
          message: message,
          errors: errors
        }, status: status
      end

      # Serializes one record or a collection with ActiveModelSerializers.
      def serialize_resource(resource, serializer: nil)
        if resource.respond_to?(:each)
          ActiveModelSerializers::SerializableResource.new(
            resource,
            each_serializer: serializer
          ).as_json
        else
          ActiveModelSerializers::SerializableResource.new(
            resource,
            serializer: serializer
          ).as_json
        end
      end

      # ---------------------------------------------------------------
      # Pagination
      # page  = which page (default 1)
      # per_page = how many items per page (default 10, max 50)
      # ---------------------------------------------------------------
      def paginate(collection)
        page = params[:page].to_i
        page = 1 if page < 1

        per_page = params[:per_page].to_i
        per_page = 10 if per_page < 1
        per_page = 50 if per_page > 50

        total_count = collection.count
        total_pages = (total_count.to_f / per_page).ceil
        records = collection.offset((page - 1) * per_page).limit(per_page)

        meta = {
          page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: total_pages
        }

        [ records, meta ]
      end

      # ---------------------------------------------------------------
      # Error handlers
      # ---------------------------------------------------------------

      def handle_record_not_found(exception)
        render_error(exception.message, nil, status: :not_found)
      end

      def handle_record_invalid(exception)
        render_error(
          "Validation failed",
          exception.record.errors.full_messages,
          status: :unprocessable_content
        )
      end
    end
  end
end
