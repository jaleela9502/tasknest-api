# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    association :user
    title { Faker::Lorem.sentence(word_count: 3) }
    body { Faker::Lorem.sentence }
    read { false }
  end
end
