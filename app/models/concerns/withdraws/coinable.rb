module Withdraws
  module Coinable
    extend ActiveSupport::Concern

    def set_fee
      if self.currency == 'btc'
        self.fee = FeeTrade.where(:currency => 2)[0]['amount'].to_f || 0.0001
      elsif self.currency == 'xrp'
        self.fee = FeeTrade.where(:currency => 5)[0]['amount'].to_f || 0.0001
      elsif self.currency == 'bch'
        self.fee = FeeTrade.where(:currency => 10)[0]['amount'].to_f || 0.0001
      elsif self.currency == 'btg'
        self.fee = FeeTrade.where(:currency => 12)[0]['amount'].to_f || 0.0001
      elsif self.currency == 'eth'
        self.fee = FeeTrade.where(:currency => 4)[0]['amount'].to_f || 0.0001
      elsif self.currency == 'etc'
        self.fee = FeeTrade.where(:currency => 6)[0]['amount'].to_f || 0.0001
      elsif self.currency == 'kbr'
        self.fee = 0
      end
    end

    def blockchain_url
      currency_obj.blockchain_url(txid)
    end

    def address_url
      currency_obj.address_url(fund_uid)
    end

    def audit!
      if ['btc', 'bch', 'btg'].include? self.currency
        result = CoinRPC[self.currency].validateaddress(fund_uid)
        if result.nil? || (result[:isvalid] == false)
          Rails.logger.info "#{self.class.name}##{id} uses invalid address: #{fund_uid.inspect}"
          reject
          save!
        elsif PaymentAddress.find_by_address(fund_uid)
          Rails.logger.info "#{self.class.name}##{id} uses hot wallet address: #{fund_uid.inspect}"
          reject
          save!
        else
          super
        end
      elsif self.currency == 'xrp'
        result = CoinRPC['xrp'].account_info([{
            "account": fund_uid,
            "strict": true,
            "ledger_index": "current",
            "queue": true
          }])
        if result.nil? || result['validated'].nil?
          Rails.logger.info "#{self.class.name}##{id} uses invalid address: #{fund_uid.inspect}"
          reject
          save!
        # elsif (result[:ismine] == true) || PaymentAddress.find_by_address(fund_uid)
        elsif PaymentAddress.find_by_address(fund_uid)
          Rails.logger.info "#{self.class.name}##{id} uses hot wallet address: #{fund_uid.inspect}"
          reject
          save!
        else
          super
        end
      elsif self.currency == 'eth' || self.currency == 'etc' || self.currency == 'kbr'
        if is_address(fund_uid) == false
          Rails.logger.info "#{self.class.name}##{id} uses invalid address: #{fund_uid.inspect}"
          reject
          save!
        elsif (is_address(fund_uid) == true) || PaymentAddress.find_by_address(fund_uid)
          super
        end
      end
    end

    def as_json(options={})
      super(options).merge({
        blockchain_url: blockchain_url,
        address_url: address_url
      })
    end

    def is_address(address)
      regex1 = /^(0x)?[0-9a-f]{40}$/i
      regex2 = /^(0x)?[0-9A-F]{40}$/
      if !(address =~ regex1)
        return false
      elsif (address =~ regex1) || (address =~ regex2)
        return true
      else
        return is_checksum_ address(address)
      end
    end
  end
end

