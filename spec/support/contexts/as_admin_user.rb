# frozen_string_literal: true

RSpec.shared_context "as admin user" do
  let(:user) { Fabricate(:user, admin: true) }
  let(:auth_header) { { "Authorization" => "Token token=#{user.api_key}" } }
end
