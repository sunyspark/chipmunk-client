# frozen_string_literal: true

require "rails_helper"

RSpec.describe V1::QueueItemsController, type: :routing do
  describe "routing" do
    it "routes to #create" do
      expect(post: "/v1/requests/1/complete").to route_to("v1/queue_items#create", bag_id: "1")
    end

    it "routes to #index" do
      expect(get: "/v1/queue").to route_to("v1/queue_items#index")
    end

    it "routes to #show" do
      expect(get: "/v1/queue/1").to route_to("v1/queue_items#show", id: "1")
    end

    xit "routes to #destroy" do
      expect(delete: "/v1/queue/1").to route_to("v1/queue_items#destroy", id: "1")
    end
  end
end
