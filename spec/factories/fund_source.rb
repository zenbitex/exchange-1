FactoryGirl.define do
  factory :fund_source do
    extra 'bitcoin'
    uid { Faker::Bitcoin.address }
    is_locked false
    currency 'btc'

    member { create(:member) }

    trait :jpy do
      extra 'bc'
      uid '123412341234'
      currency 'jpy'
    end

    factory :jpy_fund_source, traits: [:jpy]
    factory :btc_fund_source
  end
end

