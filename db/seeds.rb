ADMIN_EMAIL = 'xenhyipcrypto@gmail.com'
ADMIN_PASSWORD = 'P3gajahan0101'

admin_identity = Identity.find_or_create_by(email: ADMIN_EMAIL)
admin_identity.password = admin_identity.password_confirmation = ADMIN_PASSWORD
admin_identity.is_active = true
admin_identity.save!

admin_member = Member.find_or_create_by(email: ADMIN_EMAIL)
admin_member.authentications.build(provider: 'identity', uid: admin_identity.id)
admin_member.role = 1
admin_member.account_class = 3
admin_member.activated = true
admin_member.save!

id_document = IdDocument.find_by(member_id: 1)
id_document.aasm_state = "verified"
id_document.is_address = 1
id_document.save!

two_factor = TwoFactor.where(member_id: 1, type: "TwoFactor::Sms").first
two_factor.activated = true
two_factor.save!

if Rails.env == 'development'
  NORMAL_PASSWORD = 'PassWord'

  foo = Identity.create(email: 'foo@zenbitex.com', password: NORMAL_PASSWORD, password_confirmation: NORMAL_PASSWORD, is_active: true)
  foo_member = Member.create(email: foo.email)
  foo_member.authentications.build(provider: 'identity', uid: foo.id)
  foo_member.tag_list.add 'vip'
  foo_member.tag_list.add 'hero'
  foo_member.save

  bar = Identity.create(email: 'bar@zenbitex.com', password: NORMAL_PASSWORD, password_confirmation: NORMAL_PASSWORD, is_active: true)
  bar_member = Member.create(email: bar.email)
  bar_member.authentications.build(provider: 'identity', uid: bar.id)
  bar_member.tag_list.add 'vip'
  bar_member.tag_list.add 'hero'
  bar_member.save
end

status_list = [
   {id: 1, status_id: 0, name: "Processing"},
   {id: 2, status_id: 1, name: "Accepted"},
   {id: 3, status_id: 2, name: "Rejected"}
]

while !status_list.empty? do
  begin
    Statuses.create(status_list)
  rescue
    status_list = status_list.drop(1)
  end
end

exchange_rate = [
   {id: 1, currency: "jpy", rate: 6},
   {id: 2, currency: "btc", rate: 0.0001},
   {id: 3, currency: "usd", rate: 0.05}
]



while !exchange_rate.empty? do
  begin
    ExchangeRates.create(exchange_rate)
  rescue
    exchange_rate = exchange_rate.drop(1)
  end
end

currencies = [
   {id: 1, currency: "jpy"},
   {id: 2, currency: "btc"},
   {id: 3, currency: "usd"}
   {id: 4, currency: "eth"},
   {id: 5, currency: "doge"},
   # {id: 6, currency: "cny"}
]

while !currencies.empty? do
  begin
    Currencies.create(currencies)
  rescue
    currencies = currencies.drop(1)
  end
end

options = [
   {id: 1,taocoin: 100, currency: 1, amount: 250},
   {id: 2,taocoin: 500, currency: 1, amount: 1250},
   {id: 3,taocoin: 1000, currency: 1, amount: 2500},
   {id: 4,taocoin: 100, currency: 2, amount: 0.01},
   {id: 5,taocoin: 500, currency: 2, amount: 0.05},
   {id: 6,taocoin: 1000, currency: 2, amount: 0.1},
   {id: 7,taocoin: 100, currency: 3, amount: 5},
   {id: 8,taocoin: 500, currency: 3, amount: 25},
   {id: 9,taocoin: 1000, currency: 3, amount: 50}
]

while !options.empty? do
  begin
    BuyOptions.create(options)
  rescue
    options = options.drop(1)
  end
end

fees = [
   {id: 1, currency: 2, amount: 0.0001},
   {id: 2, currency: 3, amount: 1},
   {id: 3, currency: 4, amount: 0.0001},
   {id: 4, currency: 5, amount: 0.0001}
]

while !fees.empty? do
  begin
    FeeTrade.create(fees)
  rescue
    fees = fees.drop(1)
  end
end
