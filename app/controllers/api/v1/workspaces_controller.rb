# frozen_string_literal: true

module Api
  module V1
    # WorkspacesController — CRUD for workspaces + invite members.
    class WorkspacesController < BaseController
      before_action :set_workspace, only: [ :show, :update, :destroy, :invite ]
      before_action :ensure_member!, only: [ :show ]
      before_action :ensure_admin!, only: [ :update, :invite ]
      before_action :ensure_owner!, only: [ :destroy ]

      # GET /api/v1/workspaces
      def index
        workspaces = current_user.workspaces.order(created_at: :desc)
        records, meta = paginate(workspaces)

        render_success(
          serialize_resource(records, serializer: WorkspaceSerializer),
          "Workspaces retrieved",
          meta: meta
        )
      end

      # GET /api/v1/workspaces/:id
      def show
        render_success(
          serialize_resource(@workspace, serializer: WorkspaceSerializer),
          "Workspace retrieved"
        )
      end

      # POST /api/v1/workspaces
      def create
        workspace = current_user.owned_workspaces.new(workspace_params)

        if workspace.save
          render_success(
            serialize_resource(workspace, serializer: WorkspaceSerializer),
            "Workspace created",
            status: :created
          )
        else
          render_error("Workspace creation failed", workspace.errors.full_messages)
        end
      end

      # PATCH /api/v1/workspaces/:id
      def update
        if @workspace.update(workspace_params)
          render_success(
            serialize_resource(@workspace, serializer: WorkspaceSerializer),
            "Workspace updated"
          )
        else
          render_error("Workspace update failed", @workspace.errors.full_messages)
        end
      end

      # DELETE /api/v1/workspaces/:id
      def destroy
        @workspace.destroy!
        render_success(nil, "Workspace deleted")
      end

      # POST /api/v1/workspaces/:id/invite
      # Body: { email, role }
      # Invites an existing user into the workspace by email.
      def invite
        email = params[:email].to_s.strip.downcase
        role = params[:role].presence || "member"

        unless Membership::ROLES.include?(role) && role != "owner"
          return render_error("Role must be admin or member")
        end

        invited_user = User.find_by(email: email)
        if invited_user.nil?
          return render_error("No user found with that email", nil, status: :not_found)
        end

        membership = @workspace.memberships.find_or_initialize_by(user: invited_user)
        membership.role = role

        if membership.save
          NotificationService.notify(
            user: invited_user,
            title: "Workspace invitation",
            body: "You were added to workspace \"#{@workspace.name}\" as #{role}."
          )

          render_success(
            serialize_resource(membership, serializer: MembershipSerializer),
            "Member invited",
            status: :created
          )
        else
          render_error("Invite failed", membership.errors.full_messages)
        end
      end

      private

      def set_workspace
        @workspace = Workspace.find(params[:id])
      end

      def workspace_params
        params.permit(:name, :description)
      end

      def ensure_member!
        require_workspace_member!(@workspace)
      end

      def ensure_admin!
        require_workspace_admin!(@workspace)
      end

      def ensure_owner!
        membership = require_workspace_member!(@workspace)
        return if membership.nil?

        return if membership.owner?

        render_error("Only the workspace owner can delete it.", nil, status: :forbidden)
      end
    end
  end
end
