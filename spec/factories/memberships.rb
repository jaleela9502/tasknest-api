# frozen_string_literal: true

FactoryBot.define do
  factory :membership do
    association :user
    association :workspace
    role { "member" }
  end
end
