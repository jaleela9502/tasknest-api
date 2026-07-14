# frozen_string_literal: true

# Makes FactoryBot methods available in all specs without
# writing FactoryBot.create(...) — you can just write create(...).
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
