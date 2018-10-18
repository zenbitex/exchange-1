class PaymentSystem < ActiveRecord::Base
  STATUS_SUCCESS = "success"
  STATUS_UNSENT = "unsent"
  STATUS_CONFIRMING = "confirming"
  STATUS_INVALID_AMOUNT= "invalid amount"
end
