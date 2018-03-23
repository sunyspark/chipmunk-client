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

  def send_request
    get :show, params: { key => record.send(key) }
  end

  def nonexistent_record
    double(:nonexistent,  key => 'nonexistent')
  end

  before(:each) do
    request.headers.merge! auth_header
  end

  context "as unauthenticated user" do
    include_context "as unauthenticated user"
    let(:record) { factory.call }
    it "returns 401" do
      send_request
      expect(response).to have_http_status(401)
    end
    it "renders nothing" do
      send_request
      expect(response).to render_template(nil)
    end
  end

  context "as underprivileged user" do
    include_context "as underprivileged user"
    context "the record belongs to the user" do
      let(:record) { factory.call(user) }
      it "returns 200" do
        send_request
        expect(response).to have_http_status(200)
      end
      it "renders the record" do
        send_request
        expect(assigns(assignee)).to eql(record)
      end
      it "renders the correct template" do
        send_request
        expect(response).to render_template(template)
      end
    end
    context "the record does not belong to the user" do
      let(:record) { factory.call }
      it "returns 403" do
        send_request
        expect(response).to have_http_status(403)
      end
      it "renders nothing" do
        send_request
        expect(response).to render_template(nil)
      end
    end

    context "the record does not exist" do
      let(:record) { nonexistent_record }
      it "raises an ActiveRecord::RecordNotFound"do
        expect { send_request }.to raise_exception ActiveRecord::RecordNotFound
      end
    end
  end
  context "as admin" do
    include_context "as admin user"
    context "the record belongs to the user" do
      let(:record) { factory.call(user) }
      it "returns 200" do
        send_request
        expect(response).to have_http_status(200)
      end
      it "renders the record" do
        send_request
        expect(assigns(assignee)).to eql(record)
      end
      it "renders the correct template" do
        send_request
        expect(response).to render_template(template)
      end
    end
    context "the record does not belong to the user" do
      let(:record) { factory.call }
      it "returns 200" do
        send_request
        expect(response).to have_http_status(200)
      end
      it "renders the record" do
        send_request
        expect(assigns(assignee)).to eql(record)
      end
      it "renders the correct template" do
        send_request
        expect(response).to render_template(template)
      end
    end

    context "the record does not exist" do
      let(:record) { nonexistent_record }
      it "raises an ActiveRecord::RecordNotFound"do
        expect { send_request }.to raise_exception ActiveRecord::RecordNotFound
      end
    end
  end
end
