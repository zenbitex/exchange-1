Rails.application.eager_load! if Rails.env.development?

class ActionDispatch::Routing::Mapper
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join("config/routes/#{routes_name}.rb")))
  end
end

Exchangepro::Application.routes.draw do
  get "payment_address" => "welcome#payment_address"
  get "payment_system" => "private/api_payment#index"
  post "create_api_payment" => "private/api_payment#create_api"
  unless Rails.env.production?
    resources :invite_friends, only: [:index]
    get "buy_coin" => "private/buy_coin#show"
    post "buy_coin/create" => "private/buy_coin#create"
    post "buy_coin/save_data" => "private/buy_coin#save_data"
  end

  get 'chatting' => 'chats#chatting'
  resources :chats
  get 'chat/:id' => 'chats#chat'
  scope :chatting do
    get "chats(.:format)" => "chats#index"
    get "chats/:id(.:format)" => "chats#show"
    get "chats/:id/messages(.:format)" => "chats#messages"
  end

  # get "/faqs" => 'faqs#index'
  # get '/faqs_create_account' => 'faqs#create_account'
  # get '/faqs_change_info_register' => 'faqs#change_info_register'
  # get '/faqs_pass_login' => 'faqs#about_pass_login'
  # get '/faqs_deposit_withdraw_coin' => 'faqs#deposit_withdraw_coin'
  # get '/faqs_trades' => 'faqs#trade'
  # get '/faqs_recived_send_coin' => 'faqs#recived_send_coin'
  # get '/faqs_about_ico' => 'faqs#about_ico'

  get "sendcoind/new"
  get '/about_us' => 'welcome#about'
  use_doorkeeper
  get "/contacts" => "contacts#new"
  resources "contacts", only: [:create]
  match 'admin/contacts_us/to_all_new', to: 'admin/contacts_us#to_all_new', via: 'get'
  match 'admin/contacts_us/to_all', to: 'admin/contacts_us#send_to_all', via: 'post'

  root 'welcome#index'
  # get '/term_of_use' => 'welcome#term_of_use'
  get '/company_about' => 'welcome#company_about'

  if Rails.env.development?
    mount MailsViewer::Engine => '/mails'
  end

  get '/signin' => 'sessions#new', :as => :signin
  get '/wait_activation' => 'sessions#wait_activation'
  get '/send_email_activation' => 'sessions#send_email_activation'
  get '/signup' => 'identities#new', :as => :signup
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure', :as => :failure
  get 'success_message' => 'welcome#success_message'
  get 'about-us'=> 'welcome#about'
  match '/auth/:provider/callback' => 'sessions#create', via: [:get, :post]
  get '/confirm_password' => 'identities#confirm_password'
  # post '/verify_password' => 'identities#verify_password'
  post '/confirm_password' => 'identities#verify_password'
  get '/update_email' => 'identities#update_email'
  post '/update_email' => 'identities#change_email'

  resource :member, :only => [:edit, :update]
  resource :identity, :only => [:edit, :update]
  resources :accounts, only: :index

  namespace :verify do
    resource :sms_auth,    only: [:show, :update]
    resource :google_auth, only: [:show, :update, :edit, :destroy]
  end

  namespace :authentications do
    resources :emails, only: [:new, :create, :edit, :update]
    resources :identities, only: [:new, :create]
    resource :weibo_accounts, only: [:destroy]
  end

  get "/security" => "securities#edit"
  post "/security" => "securities#update"

  scope :constraints => { id: /[a-zA-Z0-9]{32}/ } do
    resources :reset_passwords
    resources :activations, only: [:new, :edit, :update]
    resources :activation_emails, only: [:edit]
  end

  resources :chats

  get '/chat/:id' => 'chats#chat'
  get '/get_chat_name' => 'chats#get_name'
  post '/update_chat_name' => 'chats#change_name'

  scope :groupchat do
    get "/chats(.:format)" => "chats#index"
    get "/chats/:id(.:format)" => "chats#show"
    get "/chats/:id/messages(.:format)" => "chats#messages"
  end

  get '/documents/api_v2'
  get '/documents/websocket_api'
  get '/documents/oauth'
  resources :documents, only: [:show]
  resources :two_factors, only: [:show, :index, :update]
  resources :two_factors_access, only: [:index]
  post 'two_factors_access/verify', to: 'two_factors_access#verify'
  get "confirm_two_factor", to: "verify/google_auths#confirm_two_factor"
  post 'two_factor_verify', to: 'verify/google_auths#two_factor_verify'

  scope module: :private do
    get '/affiliates' => 'affiliates#index'
    unless Rails.env.production?
      post '/coin_trade/buy_create', to: 'coin_trades#buy_create'
      post '/coin_trade/sell_create', to: 'coin_trades#sell_create'
      get '/coin_trade/load_history', to: 'coin_trades#load_history'
      get 'download_xls_affiliate_proof' => "affiliates#download_xls_affiliate_proof"
    end

    resources :coin_trades, only: [:index]
    get '/id_document', to: 'id_documents#edit'
    # resource  :id_document, only: [:edit, :update]
    get '/bank_accounts/show', to: 'bank_accounts#show'
    put '/bank_accounts/edit', to: 'bank_accounts#update'
    patch '/bank_accounts/edit', to: 'bank_accounts#update'
    post '/bank_accounts/new', to: 'bank_accounts#create'
    resource :bank_accounts, only: [:edit, :new]

    resources :sendcoin, :only => [:create]
    get "/sendcoin" => 'sendcoin#new'
    get "/add_or_delete_email" => 'sendcoin#add_or_delete_email'
    get "/taocoin_exchange" => 'taocoin_exchange#new'
    get '/deposit_infomation' => 'deposit_infomations#new'
    resource :deposit_infomations, only: [:edit, :update, :create]


    resources :taocoin_exchange do
      collection do
        post 'create'
      end
    end
    resources :settings, only: [:index]

    patch '/api_tokens/:id/edit', to: 'api_tokens#update'
    resources :api_tokens do
      member do
        delete :unbind
      end
    end

    resources :arbs, only: [:index, :update, :edit, :create]
    # get "arbs" => 'arbs#index'

    resources :fund_sources, only: [:create, :update, :destroy]

    resources :funds, only: [:index] do
      collection do
        post :gen_address
      end
    end

    namespace :deposits do
      Deposit.descendants.each do |d|
        resources d.resource_name do
          collection do
            post :gen_address
          end
        end
      end
    end

    namespace :withdraws do
      Withdraw.descendants.each do |w|
        resources w.resource_name
      end
    end

    resources :account_versions, :only => :index

    resources :exchange_assets, :controller => 'assets' do
      member do
        get :partial_tree
      end
    end

    get '/history/orders' => 'history#orders', as: :order_history
    get '/history/trades' => 'history#trades', as: :trade_history
    get '/history/sendcoin' => 'history#sendcoin', as: :sendcoin_history
    get '/history/receivecoin' => 'history#receivecoin', as: :receivecoin_history

    resources :markets, :only => :show, :constraints => MarketConstraint do
      resources :orders, :only => [:index, :destroy] do
        collection do
          post :clear
        end
      end
      resources :order_bids, :only => [:create] do
        collection do
          post :clear
        end
      end
      resources :order_asks, :only => [:create] do
        collection do
          post :clear
        end
      end
    end

    post '/pusher/auth', to: 'pusher#auth'

    resources :tickets, only: [:index, :new, :create, :show] do
      member do
        patch :close
      end
      resources :comments, only: [:create]
    end
  end

  draw :admin

  mount APIv2::Mount => APIv2::Mount::PREFIX
  mount V1::Mount => V1::Mount::PREFIX
end
