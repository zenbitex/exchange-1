class Currency < ActiveYamlBase
  include International
  include ActiveHash::Associations

  field :visible, default: true

  self.singleton_class.send :alias_method, :all_with_invisible, :all
  def self.code_to_id code
    (find_by_code code).id
  end
  def self.id_to_code id
    find_by_id(1).code
  end
  def self.all
    all_with_invisible.select &:visible
  end

  def self.enumerize
    all_with_invisible.inject({}) {|memo, i| memo[i.code.to_sym] = i.id; memo}
  end

  def self.codes
    @keys ||= all.map &:code
  end

  def self.ids
    @ids ||= all.map &:id
  end

  def self.assets(code)
    find_by_code(code)[:assets]
  end

  def precision
    self[:precision]
  end

  def self.precision(currency)
    currency = where(code: currency).first
    currency[:precision]
  end

  def api
    raise unless coin?
    CoinRPC[code]
  end

  def fiat?
    not coin?
  end

  def balance_cache_key
    "exchangepro:hotwallet:#{code}:balance"
  end

  def balance
    Rails.cache.read(balance_cache_key) || 0
  end

  def decimal_digit
    self.try(:default_decimal_digit) || (fiat? ? 2 : 4)
  end

  def refresh_balance
    Rails.cache.write(balance_cache_key, api.safe_getbalance) if coin?
  end

  def blockchain_url(txid)
    raise unless coin?
    blockchain.gsub('#{txid}', txid.to_s)
  end

  def address_url(address)
    raise unless coin?
    self[:address_url].try :gsub, '#{address}', address
  end

  def quick_withdraw_max
    @quick_withdraw_max ||= BigDecimal.new self[:quick_withdraw_max].to_s
  end

  def address
    currency_addr = 'address_dev'

    case Rails.env
    when 'staging'
      currency_addr = 'address_staging'
    when 'production'
      currency_addr = 'address_product'
    end

    self.assets['accounts'][0][currency_addr]
  end

  def password
    currency_pass = 'password'
    self.assets['accounts'][0][currency_pass]
  end

  def password_admin
    currency_pass = 'password_admin'
    self.assets['accounts'][0][currency_pass]
  end

  def address_contract
    currency_add = 'address_contract'
    self.assets['accounts'][0][currency_add]
  end

  def as_json(options = {})
    {
      key: key,
      code: code,
      coin: coin,
      blockchain: blockchain
    }
  end

  def summary
    locked = Account.locked_sum(code)
    balance = Account.balance_sum(code)
    sum = locked + balance

    coinable = self.coin?
    hot = coinable ? self.balance : nil
    address = self.address

    {
      id: self.id,
      name: self.code.upcase,
      sum: sum,
      balance: balance,
      locked: locked,
      coinable: coinable,
      hot: hot,
      address: address
      }
  end
end
