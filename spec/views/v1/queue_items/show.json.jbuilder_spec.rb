# frozen_string_literal: true

require "rails_helper"

describe "/v1/queue_items/show.json.jbuilder" do
  context "when pending" do
    let(:queue_item) { Fabricate(:queue_item, status: :pending) }
    let(:expected) do
      {
        id:         queue_item.id,
        request:    "/v1/requests/#{queue_item.bag.bag_id}",
        status:     "PENDING",
        created_at: queue_item.created_at.to_formatted_s(:default),
        updated_at: queue_item.updated_at.to_formatted_s(:default)
      }
    end
    it "renders the correct json" do
      assign(:queue_item, queue_item)
      render
      expect(JSON.parse(rendered, symbolize_names: true)).to eql(expected)
    end
  end

  context "when done" do
    let(:queue_item) { Fabricate(:queue_item, status: :done) }
    let(:expected) do
      {
        id:         queue_item.id,
        request:    "/v1/requests/#{queue_item.bag.bag_id}",
        bag:        "/v1/bags/#{queue_item.bag.bag_id}",
        status:     "DONE",
        created_at: queue_item.created_at.to_formatted_s(:default),
        updated_at: queue_item.updated_at.to_formatted_s(:default)
      }
    end
    it "renders the correct json" do
      assign(:queue_item, queue_item)
      render
      expect(JSON.parse(rendered, symbolize_names: true)).to eql(expected)
    end
  end

  context "when failed" do
    let(:errors) { ["error1", "error2", "error3"] }
    let(:queue_item) { Fabricate(:queue_item, status: :failed, error: errors.join("\n")) }
    let(:expected) do
      {
        id:         queue_item.id,
        request:    "/v1/requests/#{queue_item.bag.bag_id}",
        status:     "FAILED",
        error:      errors.join("\n"),
        created_at: queue_item.created_at.to_formatted_s(:default),
        updated_at: queue_item.updated_at.to_formatted_s(:default)
      }
    end
    it "renders the correct json" do
      assign(:queue_item, queue_item)
      render
      expect(JSON.parse(rendered, symbolize_names: true)).to eql(expected)
    end
  end
end
