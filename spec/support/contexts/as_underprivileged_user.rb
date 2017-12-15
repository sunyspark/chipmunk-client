# frozen_string_literal: true

RSpec.shared_context "as underprivileged user" do
  let(:user) { Fabricate(:user, admin: false) }
  let(:auth_header) { { "Authorization" => "Token token=#{user.api_key}" } }
end
