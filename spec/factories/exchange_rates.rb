# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :exchange_rate, :class => 'ExchangeRates' do
    currency "MyString"
    rate "9.99"
  end
end
