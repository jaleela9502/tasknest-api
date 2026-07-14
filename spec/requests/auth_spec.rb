# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth API", type: :request do
  describe "POST /api/v1/auth/register" do
    it "creates a user and returns a token" do
      post "/api/v1/auth/register", params: {
        name: "Test User",
        email: "test@example.com",
        password: "password",
        password_confirmation: "password"
      }

      expect(response).to have_http_status(:created)
      expect(json_response["success"]).to eq(true)
      expect(json_response["data"]["token"]).to be_present
      expect(json_response["data"]["user"]["email"]).to eq("test@example.com")
    end

    it "returns errors for invalid data" do
      post "/api/v1/auth/register", params: {
        name: "",
        email: "bad",
        password: "123"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response["success"]).to eq(false)
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "login@example.com", password: "password") }

    it "logs in with valid credentials" do
      post "/api/v1/auth/login", params: {
        email: "login@example.com",
        password: "password"
      }

      expect(response).to have_http_status(:ok)
      expect(json_response["data"]["token"]).to be_present
    end

    it "rejects invalid credentials" do
      post "/api/v1/auth/login", params: {
        email: "login@example.com",
        password: "wrong"
      }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let!(:user) { create(:user) }

    it "blacklists the token" do
      headers = auth_headers_for(user)

      delete "/api/v1/auth/logout", headers: headers
      expect(response).to have_http_status(:ok)

      # Same token should no longer work
      get "/api/v1/profile", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "password reset" do
    let!(:user) { create(:user, email: "reset@example.com") }

    it "generates a token and resets the password" do
      post "/api/v1/auth/forgot_password", params: { email: "reset@example.com" }
      expect(response).to have_http_status(:ok)

      user.reload
      expect(user.reset_password_token).to be_present

      # Use the raw token by generating a fresh one we know
      raw_token = user.generate_password_reset_token!

      post "/api/v1/auth/reset_password", params: {
        token: raw_token,
        password: "newpassword",
        password_confirmation: "newpassword"
      }

      expect(response).to have_http_status(:ok)
      expect(user.reload.authenticate("newpassword")).to be_truthy
    end
  end
end
