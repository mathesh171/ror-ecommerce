Hadean::Application.configure do
  config.eager_load = ENV.fetch("EAGER_LOAD", "false") == "true"

  config.force_ssl = ENV.fetch("FORCE_SSL", "false") == "true"

  config.enable_reloading = false

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  if ENV["FOG_DIRECTORY"].present?
    config.action_controller.asset_host = "//#{ENV['FOG_DIRECTORY']}.s3.amazonaws.com"
  end

  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  config.cache_store = :memory_store

  config.public_file_server.enabled = true

  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", "ror-e.herokuapp.com")
  }

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify

  config.after_initialize do
    ActiveMerchant::Billing::Base.mode = :test

    ::GATEWAY = ActiveMerchant::Billing::AuthorizeNetGateway.new(
      login: Settings.authnet.login,
      password: Settings.authnet.password,
      test: true
    )

    ::CIM_GATEWAY = ActiveMerchant::Billing::AuthorizeNetCimGateway.new(
      login: Settings.authnet.login,
      password: Settings.authnet.password,
      test: true
    )
  end

  config.log_level = :info

  config.logger = ActiveSupport::TaggedLogging.new(
    ActiveSupport::Logger.new(
      Rails.root.join("log/production.log")
    )
  )

  config.assets.compile = ENV.fetch("ASSETS_COMPILE", "true") == "true"

  config.active_storage.service =
    ENV.fetch("ACTIVE_STORAGE_SERVICE", "local").to_sym
end