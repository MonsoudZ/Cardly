FactoryBot.define do
  factory :dispute_message do
    association :dispute
    sender { dispute.initiator }
    content { Faker::Lorem.paragraph }

    trait :from_initiator do
      sender { dispute.initiator }
    end

    trait :from_other_party do
      sender { dispute.other_party }
    end

    trait :from_admin do
      association :sender, factory: [:user, :admin]
      is_admin_message { true }
    end

    trait :read do
      read_at { Time.current }
    end

    trait :unread do
      read_at { nil }
    end
  end
end
