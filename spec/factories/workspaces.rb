# frozen_string_literal: true

FactoryBot.define do
  factory :workspace do
    name { Faker::Company.name }
    description { Faker::Company.catch_phrase }
    association :owner, factory: :user
  end
end
