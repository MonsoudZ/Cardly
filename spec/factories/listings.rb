FactoryBot.define do
  factory :listing do
    transient do
      owner { nil }
    end

    association :gift_card, :listed
    user { gift_card.user }
    listing_type { "sale" }
    asking_price { 90.00 }
    discount_percent { 10.00 }
    trade_preferences { nil }
    status { "active" }
    description { "Great gift card, never used!" }

    # When owner is specified, create gift_card for that user
    after(:build) do |listing, evaluator|
      if evaluator.owner.present? && listing.gift_card&.user != evaluator.owner
        listing.gift_card = create(:gift_card, :listed, user: evaluator.owner)
        listing.user = evaluator.owner
      end
    end

    trait :sale do
      listing_type { "sale" }
      asking_price { 90.00 }
      discount_percent { 10.00 }
      trade_preferences { nil }
    end

    trait :for_sale do
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

    trait :for_trade do
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
