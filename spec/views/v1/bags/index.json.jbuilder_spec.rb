require "rails_helper"
require_relative "./a_bag_view"

describe "/v1/bags/index.json.jbuilder" do
  it_behaves_like "a bag view", :bags, ->(bag) { [bag] }
end
