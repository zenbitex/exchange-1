class PrimeTransaction < ActiveRecord::Base

  validates :address_destination, :address_from, :amount, :currency, :txid, presence: true

  validates :amount, numericality: {greater_than: 0}

  validates :txid, uniqueness: true

end