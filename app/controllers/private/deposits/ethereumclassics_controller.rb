module Private
  module Deposits
    class EthereumclassicsController < ::Private::Deposits::BaseController
      include ::Deposits::CtrlCoinable
    end
  end
end
