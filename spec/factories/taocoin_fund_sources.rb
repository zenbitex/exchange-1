# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :taocoin_fund_source, :class => 'TaocoinFundSources' do
    account_id 1
    btc_address "MyString"
  end
end
