require "pathname"

module ConfigSteps

  step ":upload_field is :value" do |field, value|
    Rails.application.config.upload[field] = value
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
