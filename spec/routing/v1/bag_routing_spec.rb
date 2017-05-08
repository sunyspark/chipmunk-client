require "rails_helper"

RSpec.describe V1::BagsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/v1/bags").to route_to("v1/bags#index")
    end

    it "routes to #show" do
      expect(:get => "/v1/bags/1").to route_to("v1/bags#show", :bag_id => "1")
    end

  end
end
