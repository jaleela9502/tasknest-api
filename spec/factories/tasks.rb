# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    association :project
    association :creator, factory: :user
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    status { "todo" }
    priority { "medium" }
    due_date { Date.current + 7 }
  end
end
