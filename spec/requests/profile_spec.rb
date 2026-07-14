# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profile API", type: :request do
  let!(:user) { create(:user, name: "Old Name", email: "old@example.com") }
  let!(:headers) { auth_headers_for(user) }

  it "shows and updates the profile" do
    get "/api/v1/profile", headers: headers
    expect(response).to have_http_status(:ok)
    expect(json_response["data"]["email"]).to eq("old@example.com")

    patch "/api/v1/profile",
          params: { name: "New Name" },
          headers: headers

    expect(response).to have_http_status(:ok)
    expect(json_response["data"]["name"]).to eq("New Name")
  end

  it "rejects unauthenticated requests" do
    get "/api/v1/profile"
    expect(response).to have_http_status(:unauthorized)
  end
end
