require "rails_helper"
require "pry"

module TurnipHelper
  include Rack::Test::Methods

  def app
    Rails.application
  end
end

RSpec.configure do |config|
  config.include TurnipHelper, type: :feature

  config.before(:type => :feature) do
    @old_upload_config = Rails.application.config.upload.clone
    @old_validation_config = Rails.application.config.validation.clone
  end
  config.after(:type => :feature) do
    Rails.application.config.upload = @old_upload_config
    Rails.application.config.validation = @old_validation_config
  end
end

require_relative "support/step_definitions/placeholders"
Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', 'step_definitions', '**', "*.rb"))]
  .each {|f| require f}

#Rails.application.config.active_job.queue_adapter = :inline
ActiveJob::Base.queue_adapter = :inline
