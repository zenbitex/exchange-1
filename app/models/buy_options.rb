class BuyOptions < ActiveRecord::Base
	validates :amount, :presence => true
	validates_numericality_of :amount, :on => :create
end
