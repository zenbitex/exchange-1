# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :currency, :class => 'Currencies' do
    currency "MyString"
  end
end
