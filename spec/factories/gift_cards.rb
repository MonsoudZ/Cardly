FactoryBot.define do
  factory :gift_card do
    user
    brand
    balance { 75.50 }
    original_value { 100.00 }
    sequence(:card_number) { |n| "1234567890%06d" % n }
    pin { "1234" }
    expiration_date { 1.year.from_now }
    barcode_data { "1234567890123456" }
    notes { "Test gift card" }
    status { "active" }
    acquired_date { 30.days.ago }
    acquired_from { "gift" }

    trait :used do
      balance { 0.00 }
      status { "used" }
    end

    trait :listed do
      status { "listed" }
    end

    trait :expiring_soon do
      expiration_date { 15.days.from_now }
    end

    trait :expired do
      expiration_date { 1.day.ago }
    end

    trait :full_balance do
      balance { 100.00 }
      original_value { 100.00 }
    end

    trait :purchased do
      acquired_from { "purchased" }
    end
  end
end
