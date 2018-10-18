# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :bank_account do
    member_id 1
    bank_name "MyString"
    bank_branch "MyString"
    account_type 1
    account_number "MyString"
    owner "MyString"
  end
end
