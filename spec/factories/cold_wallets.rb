# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cold_wallet do
    currency "MyString"
    address "MyString"
    amount ""
  end
end
