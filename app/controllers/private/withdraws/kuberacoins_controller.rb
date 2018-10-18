module Private::Withdraws
  class KuberacoinsController < ::Private::Withdraws::BaseController
    include ::Withdraws::Withdrawable
  end
end
