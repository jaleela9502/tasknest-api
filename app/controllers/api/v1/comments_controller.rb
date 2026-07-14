# frozen_string_literal: true

module Api
  module V1
    # CommentsController — CRUD for comments on a task.
    class CommentsController < BaseController
      before_action :set_task, only: [ :index, :create ]
      before_action :set_comment, only: [ :show, :update, :destroy ]
      before_action :ensure_member_for_task!, only: [ :index, :create ]
      before_action :ensure_member_for_comment!, only: [ :show, :update, :destroy ]

      # GET /api/v1/tasks/:task_id/comments
      def index
        comments = @task.comments.includes(:user).order(created_at: :asc)
        records, meta = paginate(comments)

        render_success(
          serialize_resource(records, serializer: CommentSerializer),
          "Comments retrieved",
          meta: meta
        )
      end

      # GET /api/v1/comments/:id
      def show
        render_success(
          serialize_resource(@comment, serializer: CommentSerializer),
          "Comment retrieved"
        )
      end

      # POST /api/v1/tasks/:task_id/comments
      def create
        comment = @task.comments.new(comment_params)
        comment.user = current_user

        if comment.save
          # Notify the task assignee (if someone else comments)
          if @task.assignee.present? && @task.assignee_id != current_user.id
            NotificationService.notify(
              user: @task.assignee,
              title: "New comment",
              body: "#{current_user.name} commented on \"#{@task.title}\""
            )
          end

          render_success(
            serialize_resource(comment, serializer: CommentSerializer),
            "Comment created",
            status: :created
          )
        else
          render_error("Comment creation failed", comment.errors.full_messages)
        end
      end

      # PATCH /api/v1/comments/:id
      def update
        unless @comment.user_id == current_user.id
          return render_error("You can only edit your own comments", nil, status: :forbidden)
        end

        if @comment.update(comment_params)
          render_success(
            serialize_resource(@comment, serializer: CommentSerializer),
            "Comment updated"
          )
        else
          render_error("Comment update failed", @comment.errors.full_messages)
        end
      end

      # DELETE /api/v1/comments/:id
      def destroy
        unless @comment.user_id == current_user.id
          return render_error("You can only delete your own comments", nil, status: :forbidden)
        end

        @comment.destroy!
        render_success(nil, "Comment deleted")
      end

      private

      def set_task
        @task = Task.find(params[:task_id])
      end

      def set_comment
        @comment = Comment.find(params[:id])
      end

      def comment_params
        params.permit(:body)
      end

      def ensure_member_for_task!
        require_workspace_member!(@task.project.workspace)
      end

      def ensure_member_for_comment!
        require_workspace_member!(@comment.task.project.workspace)
      end
    end
  end
end
