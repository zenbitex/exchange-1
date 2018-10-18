Exchangepro::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Use a different cache store in production.
  # config.cache_store = :file_store, "tmp"
  config.cache_store = :redis_store, ENV['REDIS_URL']

  config.session_store :redis_store, :key => '_exchangepro_session', :expire_after => ENV['SESSION_EXPIRE'].to_i.minutes

  # Don't care if the mailer can't send.
  # config.action_mailer.raise_delivery_errors = false

  # config.action_mailer.delivery_method = :file
  # config.action_mailer.file_settings = { location: 'tmp/mails' }



  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
  config.action_mailer.default_url_options = { :host => ENV["URL_HOST"] }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
      enable_starttls_auto: true,
      address: "smtp.gmail.com" ,
      port: 587,
      domain: "gmail.com" ,
      authentication: :login,
      user_name: "maxbox2018php@gmail.com",
      password: "maxbox2018php@@"
  }

  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = false
    Bullet.bullet_logger = true
    Bullet.console = true
    # Bullet.growl = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end

  # config.action_mailer.default_url_options = { :host => "192.168.1.153:3000" }
  # Send email in development mode.
  # config.action_mailer.perform_deliveries = true

  config.active_record.default_timezone = :local

  require 'middleware/i18n_js'
  require 'middleware/security'
  config.middleware.insert_before ActionDispatch::Static, Middleware::I18nJs
  config.middleware.insert_before Rack::Runtime, Middleware::Security
end
