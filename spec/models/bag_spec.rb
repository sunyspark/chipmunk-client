require 'rails_helper'

RSpec.describe Bag, type: :model do

  [:bag_id, :user_id, :external_id, :storage_location, :content_type].each do |field|
    it "#{field} is required" do
      expect(Fabricate.build(:bag, field => nil)).to_not be_valid
    end
  end

  describe "#to_param" do
    it "uses the bag id" do
      bag_id = 'made_up'
      expect(Fabricate.build(:bag, bag_id: bag_id).to_param).to eq(bag_id)
    end
  end

end
