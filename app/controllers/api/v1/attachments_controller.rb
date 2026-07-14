# frozen_string_literal: true

module Api
  module V1
    # AttachmentsController — upload, list, download, and delete files on a task.
    class AttachmentsController < BaseController
      before_action :set_task, only: [ :index, :create ]
      before_action :set_attachment, only: [ :download, :destroy ]
      before_action :ensure_member_for_task!, only: [ :index, :create ]
      before_action :ensure_member_for_attachment!, only: [ :download, :destroy ]

      # GET /api/v1/tasks/:task_id/attachments
      def index
        attachments = @task.attachments.order(created_at: :desc)
        records, meta = paginate(attachments)

        render_success(
          serialize_resource(records, serializer: AttachmentSerializer),
          "Attachments retrieved",
          meta: meta
        )
      end

      # POST /api/v1/tasks/:task_id/attachments
      # Multipart: file=<uploaded file>
      def create
        unless params[:file].present?
          return render_error("File is required")
        end

        attachment = @task.attachments.new(user: current_user)
        uploaded_file = params[:file]
        attachment.filename = uploaded_file.original_filename
        attachment.file.attach(uploaded_file)

        if attachment.save
          render_success(
            serialize_resource(attachment, serializer: AttachmentSerializer),
            "Attachment uploaded",
            status: :created
          )
        else
          render_error("Attachment upload failed", attachment.errors.full_messages)
        end
      end

      # GET /api/v1/attachments/:id/download
      def download
        unless @attachment.file.attached?
          return render_error("File not found", nil, status: :not_found)
        end

        # Stream the file to the browser as a download
        send_data @attachment.file.download,
                  filename: @attachment.filename.presence || @attachment.file.filename.to_s,
                  type: @attachment.file.content_type,
                  disposition: "attachment"
      end

      # DELETE /api/v1/attachments/:id
      def destroy
        @attachment.destroy!
        render_success(nil, "Attachment deleted")
      end

      private

      def set_task
        @task = Task.find(params[:task_id])
      end

      def set_attachment
        @attachment = Attachment.find(params[:id])
      end

      def ensure_member_for_task!
        require_workspace_member!(@task.project.workspace)
      end

      def ensure_member_for_attachment!
        require_workspace_member!(@attachment.task.project.workspace)
      end
    end
  end
end
