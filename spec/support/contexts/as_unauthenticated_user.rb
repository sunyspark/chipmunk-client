RSpec.shared_context "as unauthenticated user" do
  let(:user) { Fabricate(:user) }
  let(:auth_header) {{"Authorization" => "Token token=bad_token"}}
end