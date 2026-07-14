# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    association :workspace
    name { Faker::App.name }
    description { Faker::Lorem.sentence }
  end
end
