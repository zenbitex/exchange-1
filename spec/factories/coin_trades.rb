# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :coin_trade do
    currency "MyString"
    payment_type "MyString"
    amount "9.99"
    price "9.99"
    trade_type "MyString"
  end
end
