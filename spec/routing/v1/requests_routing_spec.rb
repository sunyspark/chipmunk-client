require "rails_helper"

RSpec.describe V1::RequestsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/v1/requests").to route_to("v1/requests#index")
    end

    it "routes to #show" do
      expect(:get => "/v1/requests/1").to route_to("v1/requests#show", :bag_id => "1")
    end

    it "routes to #create" do
      expect(:post => "/v1/requests").to route_to("v1/requests#create")
    end

  end
end

# require "rails_helper"
#
# RSpec.describe BagsController, type: :routing do
#   describe "routing" do
#
#     it "routes to #index" do
#       expect(:get => "/bags").to route_to("bags#index")
#     end
#
#
#     it "routes to #show" do
#       expect(:get => "/bags/1").to route_to("bags#show", :id => "1")
#     end
#
#
#     it "routes to #create" do
#       expect(:post => "/bags").to route_to("bags#create")
#     end
#
#     it "routes to #update via PUT" do
#       expect(:put => "/bags/1").to route_to("bags#update", :id => "1")
#     end
#
#     it "routes to #update via PATCH" do
#       expect(:patch => "/bags/1").to route_to("bags#update", :id => "1")
#     end
#
#     it "routes to #destroy" do
#       expect(:delete => "/bags/1").to route_to("bags#destroy", :id => "1")
#     end
#
#   end
# end
