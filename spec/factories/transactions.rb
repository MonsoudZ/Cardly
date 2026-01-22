FactoryBot.define do
  factory :transaction do
    buyer factory: :user
    seller factory: :user
    listing
    transaction_type { "sale" }
    status { "pending" }
    amount { 90.00 }
    message { "I'd like to buy this card!" }
    offered_gift_card { nil }

    trait :sale do
      transaction_type { "sale" }
      amount { 90.00 }
      offered_gift_card { nil }
    end

    trait :trade do
      transaction_type { "trade" }
      amount { nil }
      association :offered_gift_card, factory: :gift_card
    end

    trait :pending do
      status { "pending" }
    end

    trait :accepted do
      status { "accepted" }
    end

    trait :rejected do
      status { "rejected" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :countered do
      status { "countered" }
      original_amount { 85.00 }
      counter_amount { 92.00 }
      counter_message { "I can do $92 for this card" }
      countered_at { Time.current }
      expires_at { 48.hours.from_now }
    end

    trait :expired do
      status { "expired" }
      expires_at { 1.hour.ago }
    end

    trait :with_expiration do
      expires_at { 48.hours.from_now }
    end
  end
end
