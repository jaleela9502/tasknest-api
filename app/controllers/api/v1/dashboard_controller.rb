# frozen_string_literal: true

module Api
  module V1
    # DashboardController returns simple task stats for the current user.
    class DashboardController < BaseController
      # GET /api/v1/dashboard
      # Optional: ?workspace_id=1 to scope stats to one workspace.
      def show
        # Start with all workspaces the current user belongs to
        workspace_ids = current_user.workspace_ids
        workspace_ids = [ params[:workspace_id].to_i ] if params[:workspace_id].present?

        tasks = Task.joins(:project).where(projects: { workspace_id: workspace_ids })

        data = {
          total_tasks: tasks.count,
          completed: tasks.completed.count,
          pending: tasks.pending.count,
          overdue: tasks.overdue.count
        }

        render_success(data, "Dashboard stats retrieved")
      end
    end
  end
end
