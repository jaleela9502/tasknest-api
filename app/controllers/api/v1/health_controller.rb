# frozen_string_literal: true

module Api
  module V1
    # HealthController exposes a simple endpoint to confirm the API is running.
    class HealthController < BaseController
      skip_before_action :authenticate_user!

      # GET /api/v1/health
      def show
        render json: {
          success: true,
          message: "TaskNest API is running",
          version: "v1"
        }, status: :ok
      end
    end
  end
end
