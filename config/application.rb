# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Chipmunk
  class << self
    def config
      @config ||= Ettin.for(Ettin.settings_files('config', Rails.env))
    end
  end

  # eager load
  self.config

  class Application < Rails::Application
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource "*", headers: :any, methods: :any
      end
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.autoload_paths << Rails.root.join("lib")

    upload_path = Pathname.new(Rails.root)/"config"/"upload.yml"
    config.upload = YAML.load(ERB.new(upload_path.read).result)

    validation_path = Pathname.new(Rails.root)/"config"/"validation.yml"
    config.validation = YAML.load(ERB.new(validation_path.read).result)

    config.active_job.queue_adapter = :resque
  end
end
