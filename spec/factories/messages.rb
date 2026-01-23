FactoryBot.define do
  factory :message do
    association :card_transaction, factory: :transaction
    body { "Hello, I have a question about this card." }

    after(:build) do |message|
      message.sender ||= message.card_transaction&.buyer
    end

    trait :from_buyer do
      after(:build) do |message|
        message.sender = message.card_transaction.buyer
      end
    end

    trait :from_seller do
      after(:build) do |message|
        message.sender = message.card_transaction.seller
      end
    end

    trait :unread do
      read_at { nil }
    end

    trait :read do
      read_at { 1.hour.ago }
    end
  end
end
