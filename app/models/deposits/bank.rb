module Deposits
  class Bank < ::Deposit
    include ::AasmAbsolutely
    # include ::Deposits::Bankable
    # include ::FundSourceable

    def charge!(txid)
      with_lock do
        submit!
        accept!
        touch(:done_at)
      end
    end

  end
end
