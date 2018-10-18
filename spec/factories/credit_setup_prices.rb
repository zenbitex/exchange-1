# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :credit_setup_price do
    market "MyString"
    price 1.5
    enable 1
  end
end
