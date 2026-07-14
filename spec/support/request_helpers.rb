# frozen_string_literal: true

# Shared helpers for request specs.
module RequestHelpers
  def json_response
    JSON.parse(response.body)
  end

  def auth_headers_for(user)
    token = JwtService.encode(user.id)
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
