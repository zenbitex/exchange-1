# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :arb_history do
    member_id 1
    type_arb "MyString"
    tao_amount "9.99"
  end
end
