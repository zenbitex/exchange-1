# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :status, :class => 'Statuses' do
    status_id 1
    name "MyString"
  end
end
