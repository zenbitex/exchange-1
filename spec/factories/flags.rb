# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :flag, :class => 'Flags' do
    flag_name "MyString"
    value 1
  end
end
