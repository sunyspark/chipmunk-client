# frozen_string_literal: true

require "rails_helper"

RSpec.describe V1::BagsController, type: :routing do
  describe "routing" do
    describe "v1/bags" do
      it "routes to #index" do
        expect(get: "/v1/bags").to route_to("v1/bags#index")
      end

      it "routes to #show" do
        expect(get: "/v1/bags/1").to route_to("v1/bags#show", bag_id: "1")
      end
    end

    describe "v1/requests" do
      it "routes to #index" do
        expect(get: "/v1/requests").to route_to("v1/bags#index")
      end

      it "routes to #show" do
        expect(get: "/v1/requests/1").to route_to("v1/bags#show", bag_id: "1")
      end

      it "routes to #create" do
        expect(post: "/v1/requests").to route_to("v1/bags#create")
      end
    end
  end
end
