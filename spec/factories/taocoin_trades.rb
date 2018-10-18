# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :taocoin_trade, :class => 'TaocoinTrades' do
    email "MyString"
    tradecode "MyString"
    address "MyString"
    amount 1
    exchangerate "9.99"
    price "9.99"
    status_id 1
    txid "MyString"
    currency "MyString"
    fund_source "MyString"
    notification_params "MyText"
    purchased_at "2016-12-08 09:41:56"
    token "MyString"
    account_id 1
  end
end
