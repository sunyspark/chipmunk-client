
# frozen_string_literal: true

# @param factory [Proc] Proc that optionally takes a user, returns a saved record.
RSpec.shared_examples "an index endpoint" do
  let(:template) do
    described_class.to_s.gsub("Controller", "").underscore + "/index"
  end
  before(:each) do
    request.headers.merge! auth_header
    get :index, params: {}
  end
  context "as unauthenticated user" do
    include_context "as unauthenticated user"
    it "returns 401" do
      expect(response).to have_http_status(401)
    end
    it "renders nothing" do
      expect(response).to render_template(nil)
    end
  end

  context "as underprivileged user" do
    include_context "as underprivileged user"
    let!(:other) { factory.call }
    let!(:mine) { factory.call(user) }
    it "returns 200" do
      expect(response).to have_http_status(200)
    end
    it "renders only the user's records" do
      expect(assigns(assignee)).to contain_exactly(mine)
    end
    it "renders the correct template" do
      expect(response).to render_template(template)
    end
  end

  context "as admin" do
    include_context "as admin user"
    let!(:other) { factory.call }
    let!(:mine) { factory.call(user) }
    it "returns 200" do
      expect(response).to have_http_status(200)
    end
    it "renders all records" do
      expect(assigns(assignee)).to contain_exactly(mine, other)
    end
    it "renders the correct template" do
      expect(response).to render_template(template)
    end
  end
end
