FactoryBot.define do
  factory :tag do
    association :user
    sequence(:name) { |n| "Tag #{n}" }
    color { "#22C55E" }

    trait :groceries do
      name { "Groceries" }
      color { "#22C55E" }
    end

    trait :restaurants do
      name { "Restaurants" }
      color { "#F97316" }
    end

    trait :entertainment do
      name { "Entertainment" }
      color { "#8B5CF6" }
    end
  end

  factory :gift_card_tag do
    association :gift_card
    association :tag
  end
end
