# frozen_string_literal: true

module Api
  module V1
    # MembershipsController — list / update roles / remove members.
    class MembershipsController < BaseController
      before_action :set_workspace
      before_action :ensure_member!, only: [ :index ]
      before_action :ensure_admin!, only: [ :update, :destroy ]

      # GET /api/v1/workspaces/:workspace_id/memberships
      def index
        memberships = @workspace.memberships.includes(:user).order(created_at: :asc)
        records, meta = paginate(memberships)

        render_success(
          serialize_resource(records, serializer: MembershipSerializer),
          "Memberships retrieved",
          meta: meta
        )
      end

      # PATCH /api/v1/workspaces/:workspace_id/memberships/:id
      # Body: { role }
      def update
        membership = @workspace.memberships.find(params[:id])

        if membership.owner?
          return render_error("Cannot change the owner's role")
        end

        new_role = params[:role].to_s
        unless %w[admin member].include?(new_role)
          return render_error("Role must be admin or member")
        end

        membership.update!(role: new_role)
        render_success(
          serialize_resource(membership, serializer: MembershipSerializer),
          "Membership updated"
        )
      end

      # DELETE /api/v1/workspaces/:workspace_id/memberships/:id
      def destroy
        membership = @workspace.memberships.find(params[:id])

        if membership.owner?
          return render_error("Cannot remove the workspace owner")
        end

        membership.destroy!
        render_success(nil, "Member removed")
      end

      private

      def set_workspace
        @workspace = Workspace.find(params[:workspace_id])
      end

      def ensure_member!
        require_workspace_member!(@workspace)
      end

      def ensure_admin!
        require_workspace_admin!(@workspace)
      end
    end
  end
end
