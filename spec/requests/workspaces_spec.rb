# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Workspaces API", type: :request do
  let!(:user) { create(:user) }
  let!(:headers) { auth_headers_for(user) }

  describe "POST /api/v1/workspaces" do
    it "creates a workspace and adds the owner as a member" do
      post "/api/v1/workspaces",
           params: { name: "My Team", description: "A demo workspace" },
           headers: headers

      expect(response).to have_http_status(:created)
      expect(json_response["data"]["name"]).to eq("My Team")

      workspace = Workspace.last
      expect(workspace.memberships.find_by(user: user).role).to eq("owner")
    end
  end

  describe "member invite and projects/tasks flow" do
    let!(:workspace) { create(:workspace, owner: user) }
    let!(:other_user) { create(:user, email: "invitee@example.com") }

    it "invites a member and creates a project with a task" do
      post "/api/v1/workspaces/#{workspace.id}/invite",
           params: { email: "invitee@example.com", role: "member" },
           headers: headers

      expect(response).to have_http_status(:created)
      expect(workspace.members).to include(other_user)

      post "/api/v1/workspaces/#{workspace.id}/projects",
           params: { name: "Launch", description: "Launch project" },
           headers: headers

      expect(response).to have_http_status(:created)
      project_id = json_response["data"]["id"]

      post "/api/v1/projects/#{project_id}/tasks",
           params: {
             title: "Ship MVP",
             description: "Finish the first version",
             status: "todo",
             priority: "high",
             assignee_id: other_user.id,
             due_date: Date.current + 5
           },
           headers: headers

      expect(response).to have_http_status(:created)
      expect(json_response["data"]["title"]).to eq("Ship MVP")
      expect(json_response["data"]["assignee_id"]).to eq(other_user.id)

      # Assignee should get a notification
      expect(other_user.notifications.count).to be >= 1
    end
  end
end
