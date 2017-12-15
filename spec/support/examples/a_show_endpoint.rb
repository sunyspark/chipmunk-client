# frozen_string_literal: true

require "rails_helper"

# @param key [Symbol] The key serving as the id, rails default is :id
# @param factory [Proc] Proc that optionally takes a user, returns a saved record.
# @param assignee [Symbol] The variable the models are assigned to.
# @param template [String] The template to render
RSpec.shared_examples "a show endpoint" do
  let(:template) do
    described_class.to_s.gsub("Controller", "").underscore + "/show"
  end
  before(:each) do
    request.headers.merge! auth_header
    get :show, params: { key => record.send(key) }
  end
  context "as unauthenticated user" do
    include_context "as unauthenticated user"
    let(:record) { factory.call }
    it "returns 401" do
      expect(response).to have_http_status(401)
    end
    it "renders nothing" do
      expect(response).to render_template(nil)
    end
  end
  context "as underprivileged user" do
    include_context "as underprivileged user"
    context "the record belongs to the user" do
      let(:record) { factory.call(user) }
      it "returns 200" do
        expect(response).to have_http_status(200)
      end
      it "renders the record" do
        expect(assigns(assignee)).to eql(record)
      end
      it "renders the correct template" do
        expect(response).to render_template(template)
      end
    end
    context "the record does not belong to the user" do
      let(:record) { factory.call }
      it "returns 403" do
        expect(response).to have_http_status(403)
      end
      it "renders nothing" do
        expect(response).to render_template(nil)
      end
    end
  end
  context "as admin" do
    include_context "as admin user"
    context "the record belongs to the user" do
      let(:record) { factory.call(user) }
      it "returns 200" do
        expect(response).to have_http_status(200)
      end
      it "renders the record" do
        expect(assigns(assignee)).to eql(record)
      end
      it "renders the correct template" do
        expect(response).to render_template(template)
      end
    end
    context "the record does not belong to the user" do
      let(:record) { factory.call }
      it "returns 200" do
        expect(response).to have_http_status(200)
      end
      it "renders the record" do
        expect(assigns(assignee)).to eql(record)
      end
      it "renders the correct template" do
        expect(response).to render_template(template)
      end
    end
  end
end
