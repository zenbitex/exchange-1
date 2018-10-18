class BankAccount < ActiveRecord::Base
	extend Enumerize
	validates_presence_of :bank_name, :bank_branch, :account_type, :account_number, :owner
	enumerize :account_type, in: {current_bank_account: 1, ordinary_bank_account: 2}
	belongs_to :member
end
