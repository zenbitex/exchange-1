require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Exchangepro
  class Application < Rails::Application

    case Rails.env
    when "staging"
      ENV['URL_HOST']      = ENV['URL_HOST_STAGING']
      ENV['PUSHER_APP']    = ENV['PUSHER_APP_STAGING']
      ENV['PUSHER_KEY']    = ENV['PUSHER_KEY_STAGING']
      ENV['PUSHER_SECRET'] = ENV['PUSHER_SECRET_STAGING']
      ENV['RIPPLE_SERVER'] = ENV['RIPPLE_SERVER_STAGING']
    when "production"
      ENV['URL_HOST']      = ENV['URL_HOST_PRODUCT']
      ENV['PUSHER_APP']    = ENV['PUSHER_APP_PROD']
      ENV['PUSHER_KEY']    = ENV['PUSHER_KEY_PROD']
      ENV['PUSHER_SECRET'] = ENV['PUSHER_SECRET_PROD']
      ENV['S3_BUCKET_NAME'] = ENV['S3_BUCKET_NAME_SERVER']
      ENV['RIPPLE_SERVER'] = ENV['RIPPLE_SERVER_PROD']
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # config.i18n.enforce_available_locales = true
    config.i18n.default_locale = :ja
    # config.i18n.fallbacks = true

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'custom', '*.{yml}')]
    config.i18n.available_locales = ['ja','en','zh-CN']

    config.autoload_paths += %W(#{config.root}/lib #{config.root}/lib/extras)

    #config.assets.precompile += ['bootstrap-datetimepicker.css']
    config.assets.initialize_on_precompile = true

    # Precompile all available locales
    Dir.glob("#{config.root}/app/assets/javascripts/locales/*.js.erb").each do |file|
      config.assets.precompile << "locales/#{file.match(/([a-z\-A-Z]+\.js)\.erb$/)[1]}"
    end

    # Gem create affiliate link
    config.middleware.use Rack::Affiliates
    
    config.generators do |g|
      g.orm             :active_record
      g.template_engine :erb
      g.stylesheets     false
    end

    # Observer configuration
    config.active_record.observers = :transfer_observer
  end
end
