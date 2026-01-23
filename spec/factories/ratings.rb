FactoryBot.define do
  factory :rating do
    association :card_transaction, factory: [:transaction, :completed]
    score { 4 }
    comment { "Great transaction!" }
    role { "buyer" }

    # Set rater and ratee based on the transaction
    after(:build) do |rating|
      if rating.card_transaction.present?
        if rating.role == "buyer"
          rating.rater ||= rating.card_transaction.buyer
          rating.ratee ||= rating.card_transaction.seller
        else
          rating.rater ||= rating.card_transaction.seller
          rating.ratee ||= rating.card_transaction.buyer
        end
      end
    end

    trait :from_buyer do
      role { "buyer" }
    end

    trait :from_seller do
      role { "seller" }
    end

    trait :positive do
      score { 5 }
      comment { "Excellent experience!" }
    end

    trait :negative do
      score { 1 }
      comment { "Very disappointing." }
    end

    trait :neutral do
      score { 3 }
      comment { "It was okay." }
    end
  end
end
