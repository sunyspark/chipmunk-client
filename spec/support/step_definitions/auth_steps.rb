# frozen_string_literal: true

module AuthSteps
  step "I am a valid API user with username :username" do |username|
    @user = Fabricate(:user, username: username)
    header "Authorization", "Token token=#{@user.api_key}"
  end
end

RSpec.configure {|config| config.include AuthSteps }
