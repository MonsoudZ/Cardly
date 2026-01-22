FactoryBot.define do
  factory :listing do
    association :gift_card, :listed
    user { gift_card.user }
    listing_type { "sale" }
    asking_price { 90.00 }
    discount_percent { 10.00 }
    trade_preferences { nil }
    status { "active" }
    description { "Great gift card, never used!" }

    trait :sale do
      listing_type { "sale" }
      asking_price { 90.00 }
      discount_percent { 10.00 }
      trade_preferences { nil }
    end

    trait :trade do
      listing_type { "trade" }
      asking_price { nil }
      discount_percent { nil }
      trade_preferences { "Looking for Amazon or Target gift cards" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :completed do
      status { "completed" }
    end
  end
end
