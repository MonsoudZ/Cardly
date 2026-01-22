FactoryBot.define do
  factory :brand do
    sequence(:name) { |n| "Brand #{n}" }
    logo_url { "https://logo.clearbit.com/example.com" }
    website_url { "https://www.example.com" }
    category { "retail" }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :food do
      category { "food" }
    end

    trait :retail do
      category { "retail" }
    end

    trait :entertainment do
      category { "entertainment" }
    end
  end
end
