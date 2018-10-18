# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :taocoin_exchange do
    member_id 1
    amount 1
    total "9.99"
    currency 1
  end
end
