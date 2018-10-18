# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :coin_trade_price do
    currency 1
    price "9.99"
    fee 1.5
    activate_price false
  end
end
