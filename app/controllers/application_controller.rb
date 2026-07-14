# ApplicationController is the top-level controller for the entire app.
# For API v1 endpoints, prefer inheriting from Api::V1::BaseController instead —
# it adds shared JSON helpers and error handling.
class ApplicationController < ActionController::API
end
