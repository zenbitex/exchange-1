module Private::Withdraws
  class EthereumclassicsController < ::Private::Withdraws::BaseController
    include ::Withdraws::Withdrawable
  end
end
