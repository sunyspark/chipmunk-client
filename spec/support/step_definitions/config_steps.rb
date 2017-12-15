# frozen_string_literal: true

require "pathname"

module ConfigSteps

  step ":config_block.:field is :value" do |config, field, value|
    Rails.application.config.public_send(config.to_sym)[field] = value
  end

  step ":dir exists and is empty" do |dir|
    path = Pathname.new(dir)
    if path.exist?
      path.rmtree
    end
    path.mkpath
  end

end

RSpec.configure {|config| config.include ConfigSteps }
