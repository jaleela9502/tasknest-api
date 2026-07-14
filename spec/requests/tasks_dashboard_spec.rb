# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tasks, Dashboard, and Notifications", type: :request do
  let!(:user) { create(:user) }
  let!(:headers) { auth_headers_for(user) }
  let!(:workspace) { create(:workspace, owner: user) }
  let!(:project) { create(:project, workspace: workspace) }

  describe "task search / filter / sort" do
    before do
      create(:task, project: project, creator: user, title: "Write docs", status: "todo", priority: "low")
      create(:task, project: project, creator: user, title: "Fix bug", status: "done", priority: "high")
      create(:task, project: project, creator: user, title: "Review PR", status: "review", priority: "medium")
    end

    it "filters by status and searches by title" do
      get "/api/v1/projects/#{project.id}/tasks",
          params: { status: "todo", q: "docs" },
          headers: headers

      expect(response).to have_http_status(:ok)
      titles = json_response["data"].map { |task| task["title"] }
      expect(titles).to eq([ "Write docs" ])
      expect(json_response["meta"]["total_count"]).to eq(1)
    end
  end

  describe "GET /api/v1/dashboard" do
    before do
      create(:task, project: project, creator: user, status: "done")
      create(:task, project: project, creator: user, status: "todo", due_date: Date.current - 1)
      create(:task, project: project, creator: user, status: "in_progress", due_date: Date.current + 3)
    end

    it "returns task counts" do
      get "/api/v1/dashboard", headers: headers

      expect(response).to have_http_status(:ok)
      data = json_response["data"]
      expect(data["total_tasks"]).to eq(3)
      expect(data["completed"]).to eq(1)
      expect(data["pending"]).to eq(2)
      expect(data["overdue"]).to eq(1)
    end
  end

  describe "notifications" do
    let!(:notification) { create(:notification, user: user, read: false) }

    it "lists and marks notifications as read" do
      get "/api/v1/notifications", headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_response["data"].length).to eq(1)

      patch "/api/v1/notifications/#{notification.id}", headers: headers
      expect(response).to have_http_status(:ok)
      expect(notification.reload.read).to eq(true)
    end
  end

  describe "project archive / restore" do
    it "archives and restores a project" do
      post "/api/v1/projects/#{project.id}/archive", headers: headers
      expect(response).to have_http_status(:ok)
      expect(project.reload.archived?).to eq(true)

      post "/api/v1/projects/#{project.id}/restore", headers: headers
      expect(response).to have_http_status(:ok)
      expect(project.reload.archived?).to eq(false)
    end
  end

  describe "comments CRUD" do
    let!(:task) { create(:task, project: project, creator: user) }

    it "creates updates and deletes a comment" do
      post "/api/v1/tasks/#{task.id}/comments",
           params: { body: "First comment" },
           headers: headers
      expect(response).to have_http_status(:created)
      comment_id = json_response["data"]["id"]

      patch "/api/v1/comments/#{comment_id}",
            params: { body: "Updated comment" },
            headers: headers
      expect(response).to have_http_status(:ok)
      expect(json_response["data"]["body"]).to eq("Updated comment")

      delete "/api/v1/comments/#{comment_id}", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end
end
