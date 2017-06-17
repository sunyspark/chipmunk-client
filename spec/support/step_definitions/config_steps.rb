module ConfigSteps

  step ":upload_field is :value" do |field, value|
    Rails.application.config.upload[field] = value
  end

end

RSpec.configure {|config| config.include ConfigSteps }
