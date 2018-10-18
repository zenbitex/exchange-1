# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :message do
    content "MyString"
    sent_id 1
    chat_id 1
  end
end
