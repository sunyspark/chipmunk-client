require "rails_helper"

module TurnipHelper
  include Rack::Test::Methods

  def app
    Rails.application
  end
end

RSpec.configure do |config|
  config.include TurnipHelper, type: :feature
end

require_relative "support/step_definitions/placeholders"
Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', 'step_definitions', '**', "*.rb"))]
  .each {|f| require f}
