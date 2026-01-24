FactoryBot.define do
  factory :dispute do
    association :card_transaction, factory: [:transaction, :completed]
    initiator { card_transaction.buyer }
    reason { Dispute::REASONS.sample }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    status { "open" }

    trait :open do
      status { "open" }
    end

    trait :under_review do
      status { "under_review" }
      reviewed_at { Time.current }
    end

    trait :resolved do
      status { "resolved" }
      resolution { Dispute::RESOLUTIONS.sample }
      resolution_notes { Faker::Lorem.sentence }
      resolved_at { Time.current }
    end

    trait :closed do
      status { "closed" }
      resolution { Dispute::RESOLUTIONS.sample }
      resolution_notes { Faker::Lorem.sentence }
      resolved_at { 1.day.ago }
      closed_at { Time.current }
    end

    trait :card_not_working do
      reason { "card_not_working" }
    end

    trait :wrong_balance do
      reason { "wrong_balance" }
    end

    trait :fraudulent_listing do
      reason { "fraudulent_listing" }
    end
  end
end
