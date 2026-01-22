FactoryBot.define do
  factory :rating do
    association :transaction, :completed
    score { 4 }
    comment { "Great transaction!" }
    role { "buyer" }

    # Set rater and ratee based on the transaction
    after(:build) do |rating|
      if rating.transaction.present?
        if rating.role == "buyer"
          rating.rater ||= rating.transaction.buyer
          rating.ratee ||= rating.transaction.seller
        else
          rating.rater ||= rating.transaction.seller
          rating.ratee ||= rating.transaction.buyer
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
