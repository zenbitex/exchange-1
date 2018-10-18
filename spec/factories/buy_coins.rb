# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :buy_coin do
    id_buy "MyString"
    market "MyString"
    money 1.5
    price 1.5
    amount 1.5
    status 1
  end
end
