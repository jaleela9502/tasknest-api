# frozen_string_literal: true

module Api
  module V1
    # ProjectsController — CRUD plus archive / restore.
    class ProjectsController < BaseController
      before_action :set_workspace, only: [ :index, :create ]
      before_action :set_project, only: [ :show, :update, :destroy, :archive, :restore ]
      before_action :ensure_workspace_member_for_collection!, only: [ :index, :create ]
      before_action :ensure_workspace_member_for_project!, only: [ :show, :update, :destroy, :archive, :restore ]

      # GET /api/v1/workspaces/:workspace_id/projects
      # Optional: ?archived=true to list archived projects
      def index
        projects = if params[:archived].to_s == "true"
                   @workspace.projects.archived
                 else
                   @workspace.projects.active
                 end

        projects = projects.order(created_at: :desc)
        records, meta = paginate(projects)

        render_success(
          serialize_resource(records, serializer: ProjectSerializer),
          "Projects retrieved",
          meta: meta
        )
      end

      # GET /api/v1/projects/:id
      def show
        render_success(
          serialize_resource(@project, serializer: ProjectSerializer),
          "Project retrieved"
        )
      end

      # POST /api/v1/workspaces/:workspace_id/projects
      def create
        project = @workspace.projects.new(project_params)

        if project.save
          render_success(
            serialize_resource(project, serializer: ProjectSerializer),
            "Project created",
            status: :created
          )
        else
          render_error("Project creation failed", project.errors.full_messages)
        end
      end

      # PATCH /api/v1/projects/:id
      def update
        if @project.update(project_params)
          render_success(
            serialize_resource(@project, serializer: ProjectSerializer),
            "Project updated"
          )
        else
          render_error("Project update failed", @project.errors.full_messages)
        end
      end

      # DELETE /api/v1/projects/:id
      def destroy
        @project.destroy!
        render_success(nil, "Project deleted")
      end

      # POST /api/v1/projects/:id/archive
      def archive
        @project.archive!
        render_success(
          serialize_resource(@project, serializer: ProjectSerializer),
          "Project archived"
        )
      end

      # POST /api/v1/projects/:id/restore
      def restore
        @project.restore!
        render_success(
          serialize_resource(@project, serializer: ProjectSerializer),
          "Project restored"
        )
      end

      private

      def set_workspace
        @workspace = Workspace.find(params[:workspace_id])
      end

      def set_project
        @project = Project.find(params[:id])
      end

      def project_params
        params.permit(:name, :description)
      end

      def ensure_workspace_member_for_collection!
        require_workspace_member!(@workspace)
      end

      def ensure_workspace_member_for_project!
        require_workspace_member!(@project.workspace)
      end
    end
  end
end
