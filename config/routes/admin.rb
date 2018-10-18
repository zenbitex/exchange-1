namespace :admin do
  get '/', to: 'dashboard#index', as: :dashboard

  get 'manage_servers', to: 'manage_servers#index'
  get 'manage_servers/server_detail', to: 'manage_servers#server_detail'
  resources :cold_wallets
  resources :documents
  resources :id_documents,     only: [:index, :show, :update, :edit]
  post 'id_documents/send_mail_reject' => "id_documents#send_mail_reject"
  put 'id_documents/:id(.:format)/update_member_information', to: "id_documents#update_member_information"
  patch 'id_documents/:id(.:format)/update_member_information', to: "id_documents#update_member_information"
  resources :deposit_infomations, only: [:index, :show, :update]
  resource  :currency_deposit, only: [:new, :create]
  resources :proofs
  resources :reports, only: [:index]
  resources :count_orders, only: [:index]
  get 'download_xlsx_export_price', to: "reports#download_xlsx_export_price"
  get 'download_xlsx_export_balance', to: "reports#download_xlsx_export_balance"
  get 'download_xlsx_trade_fee', to: "reports#download_xlsx_trade_fee"
  get 'download_xlsx_withdraw_history', to: "reports#download_xlsx_withdraw_history"
  get 'download_xlsx_deposit_history', to: "reports#download_xlsx_deposit_history"
  get 'download_xlsx_order_ask_history', to: "reports#download_xlsx_order_ask_history"
  get 'download_xlsx_order_bid_history', to: "reports#download_xlsx_order_bid_history"
  get 'download_xlsx_trade_history', to: "reports#download_xlsx_trade_history"
  get 'download_xlsx_order_cancel_history', to: "reports#download_xlsx_order_cancel_history"

  # resources :admin_send_coin, only: [:index]
  # post 'admin_send_coin', to: "admin_send_coin#send_coin"
  # get 'email_exits', to: "admin_send_coin#email_exits"

  resources :buy_options
  resources :exchangerates
  resources :banktrades
  resources :btctrades
  resources :paypaltrades
  resources :fee_trades
  resources :arbs_history
  # resources :affiliates, only: [:index, :show]
  # resources :coin_trades, only: [:index]
  get 'download_xlsx_fee' => "fee_trades#download_xlsx_fee"
  get 'arbprofit' => "arbs_history#profit_index"
  get 'count_profit' => "arbs_history#count_profit"
  post 'share_profit' => "arbs_history#share_profit"
  get 'send_profit' => "arbs_history#send_profit"
  get 'download_xls_arb_profit' => "arbs_history#download_xls_arb_profit"
  get 'download_xls_arb_profit_by_month' => "arbs_history#download_xls_arb_profit_by_month"

  get 'send_bonus' => "id_documents#send_bonus_for_old_user"
  get 'send_missing_bonus' => "id_documents#send_missing_bonus"
  get 'set_level' => "id_documents#set_level_all"
  get 'download_xlsx_balance' => "id_documents#download_xlsx_balance"
  get 'set_postcard' => "id_documents#set_postcard"

  get 'download_xlsx_user_balance' => "user_balance#download_xlsx_user_balance"
  get 'download_xlsx_trade' => "id_documents#download_xlsx_trade"
  get 'download_xlsx_id_document' => "id_documents#download_xlsx_id_document"
  get 'download_xlsx_bank_account' => "id_documents#download_xlsx_bank_account"
  get 'download_xlsx_address' => "id_documents#download_xlsx_address"
  get 'download_xlsx_balance_account' => "dashboard#download_xlsx_balance_account"
  get 'download_xlsx_balance_account_31_7_2017' => "dashboard#download_xlsx_balance_account_31_7_2017"
  get 'download_xlsx_account_version' => "members#download_xlsx_account_version"
  get 'download_xlsx_withdraw_jpy_history' => 'withdraws/banks#download_xlsx_withdraw_jpy_history'

  resources :flags
  resources :contacts_us, only: [:index]
  get 'contacts_us/show' => "contacts_us#show"
  get 'contacts_us/create_send_email' => "contacts_us#create_send_email"
  post 'contacts_us/rep_ok_ng' => "contacts_us#rep_ok_ng"
  post 'contacts_us/send_mail' => "contacts_us#send_mail"
  get 'send_to_general_address/index' => "send_to_general_address#index"
  post 'send_to_general_address/new' => "send_to_general_address#new"
  get 'referrer' => "referrer#index"
  get 'referral_diagram' => "referral_diagram#index"
  get 'referrer_search' => "referrer#search"
  get 'user_balance' => "user_balance#index"
  get 'user_balance_search' => "user_balance#search"
  post 'credit_price' => 'fee_trades#credit_price'

  resources :coin_trade_prices, only: [:index, :edit, :update]
  get 'coin_trade_prices/activation_admin_price' => "coin_trade_prices#activate_admin_price"
  resources :flags do
      collection do
        post 'on_flag'
        post 'off_flag'
      end
    end
  resources :tickets, only: [:index, :show] do
    member do
      patch :close
    end
    resources :comments, only: [:create]
  end

  resources :members, only: [:index, :show, :edit, :update] do
    member do
      post :active
      post :toggle
    end

    resources :two_factors, only: [:destroy]
  end

  namespace :deposits do
		get 'bank_confirm' => "banks#confirm_deposit_yen"
		post 'create_deposit_yen' => "banks#create_deposit_yen"
    Deposit.descendants.each do |d|
      resources d.resource_name
    end
  end

  namespace :withdraws do
    Withdraw.descendants.each do |w|
      resources w.resource_name
    end
  end

  namespace :statistic do
    resource :members, :only => :show
    resource :orders, :only => :show
    resource :trades, :only => :show
    resource :deposits, :only => :show
    resource :withdraws, :only => :show
    resources :cloud_sale
  end
end
