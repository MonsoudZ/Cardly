FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    sequence(:name) { |n| "Test User #{n}" }

    trait :without_name do
      name { nil }
    end
  end
end
