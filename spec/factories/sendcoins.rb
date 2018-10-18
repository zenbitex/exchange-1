# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sendcoin do
    user_id_source 1
    user_id_destination 1
    amount "9.99"
    email "MyString"
    currency "MyString"
  end
end
