Rails.configuration.stripe = {
  :publishable_key => ENV['PUBLIC_KEY_STRIPE'],
  :secret_key      => ENV['SECRET_KEY_STRIPE']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]