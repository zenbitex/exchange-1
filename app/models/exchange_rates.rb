class ExchangeRates < ActiveRecord::Base
	validates :rate, :presence => true
	validates_numericality_of :rate, :on => :create

	def custom_currency
		"TAOCOIN -> " + self.currency
	end
end
