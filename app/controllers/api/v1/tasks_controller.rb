# frozen_string_literal: true

module Api
  module V1
    # TasksController — CRUD with search, filter, sort, and pagination.
    class TasksController < BaseController
      before_action :set_project, only: [ :index, :create ]
      before_action :set_task, only: [ :show, :update, :destroy ]
      before_action :ensure_member_for_project!, only: [ :index, :create ]
      before_action :ensure_member_for_task!, only: [ :show, :update, :destroy ]

      # GET /api/v1/projects/:project_id/tasks
      # Query params:
      #   q            — search title/description
      #   status       — todo | in_progress | review | done
      #   priority     — low | medium | high
      #   assignee_id  — filter by assignee
      #   sort         — title | status | priority | due_date | created_at
      #   direction    — asc | desc
      #   page, per_page
      def index
        tasks = @project.tasks.includes(:assignee, :creator)
        tasks = tasks.search(params[:q])
        tasks = tasks.filter_by_status(params[:status])
        tasks = tasks.filter_by_priority(params[:priority])
        tasks = tasks.filter_by_assignee(params[:assignee_id])
        tasks = tasks.sorted_by(params[:sort], params[:direction])

        records, meta = paginate(tasks)

        render_success(
          serialize_resource(records, serializer: TaskSerializer),
          "Tasks retrieved",
          meta: meta
        )
      end

      # GET /api/v1/tasks/:id
      def show
        render_success(
          serialize_resource(@task, serializer: TaskSerializer),
          "Task retrieved"
        )
      end

      # POST /api/v1/projects/:project_id/tasks
      def create
        task = @project.tasks.new(task_params)
        task.creator = current_user

        if task.save
          notify_assignee(task, "You were assigned a new task: \"#{task.title}\"")

          render_success(
            serialize_resource(task, serializer: TaskSerializer),
            "Task created",
            status: :created
          )
        else
          render_error("Task creation failed", task.errors.full_messages)
        end
      end

      # PATCH /api/v1/tasks/:id
      def update
        previous_assignee_id = @task.assignee_id

        if @task.update(task_params)
          # Notify if the assignee changed
          if @task.assignee_id.present? && @task.assignee_id != previous_assignee_id
            notify_assignee(@task, "You were assigned to task: \"#{@task.title}\"")
          end

          render_success(
            serialize_resource(@task, serializer: TaskSerializer),
            "Task updated"
          )
        else
          render_error("Task update failed", @task.errors.full_messages)
        end
      end

      # DELETE /api/v1/tasks/:id
      def destroy
        @task.destroy!
        render_success(nil, "Task deleted")
      end

      private

      def set_project
        @project = Project.find(params[:project_id])
      end

      def set_task
        @task = Task.find(params[:id])
      end

      def task_params
        params.permit(:title, :description, :status, :priority, :due_date, :assignee_id)
      end

      def ensure_member_for_project!
        require_workspace_member!(@project.workspace)
      end

      def ensure_member_for_task!
        require_workspace_member!(@task.project.workspace)
      end

      def notify_assignee(task, body)
        return if task.assignee.nil?
        return if task.assignee_id == current_user.id

        NotificationService.notify(
          user: task.assignee,
          title: "Task assignment",
          body: body
        )
      end
    end
  end
end
