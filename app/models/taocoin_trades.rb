class TaocoinTrades < ActiveRecord::Base
	belongs_to :account
	belongs_to :taocoin_fund_source
	before_validation :gen_tradecode
	validates_numericality_of :amount, :price, :greater_than => 0
	validates_presence_of :amount, :tradecode, :price

	WAIT = 0
    DONE = 1
    CANCEL = 2

    def self.search(start_period: nil, end_period: nil)
    	start_period = Date.parse(start_period) rescue nil
    	end_period = Date.parse(end_period) rescue nil
    	if start_period && end_period && start_period != end_period
    		result = where("updated_at >= ? AND updated_at <= ?", start_period, end_period)
    	elsif start_period && !end_period
    		result = where("updated_at >= ?", start_period)
    	elsif !start_period && end_period
    		result = where("updated_at <= ?", end_period)
        elsif start_period == end_period
            result = where("updated_at like ?", "%#{start_period}%")
    	else
    		result = all
    	end
    	result.order(updated_at: :desc)
    end

	private
	def gen_tradecode
		self.tradecode and return
		begin
			self.tradecode = "TAO#{ROTP::Base32.random_base32(8)}EXC"
    end while TaocoinTrades.where(:tradecode => self.tradecode).any?
	end
end
