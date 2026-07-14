# frozen_string_literal: true

# CORS (Cross-Origin Resource Sharing) lets a browser at one origin
# (e.g. http://localhost:5173 — a Vite/React app) call this API at another
# origin (e.g. http://localhost:3000).
#
# Without CORS, the browser would block those requests for security reasons.
#
# Restart the Rails server after changing this file.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow the React development server (Vite default port).
    origins "http://localhost:5173"

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true
  end
end
