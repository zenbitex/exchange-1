# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :buy_option, :class => 'BuyOptions' do
    taocoin "9.99"
    currency "MyString"
    amount "9.99"
  end
end
