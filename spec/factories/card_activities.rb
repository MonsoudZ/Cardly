FactoryBot.define do
  factory :card_activity do
    association :gift_card
    activity_type { "purchase" }
    amount { 10.00 }
    merchant { "Test Store" }
    occurred_at { Time.current }

    trait :purchase do
      activity_type { "purchase" }
    end

    trait :refund do
      activity_type { "refund" }
    end

    trait :adjustment do
      activity_type { "adjustment" }
    end

    trait :balance_check do
      activity_type { "balance_check" }
    end

    trait :with_description do
      description { "Test transaction description" }
    end
  end
end
