require 'rails_helper'

RSpec.shared_examples "a bag" do |factory_id,content_type|
  [:bag_id, :user_id, :external_id, :storage_location].each do |field|
    it "#{field} is required" do
      expect(Fabricate.build(factory_id, field => nil)).to_not be_valid
    end
  end

  it "#content_type is #{content_type}" do
    expect(Fabricate.build(factory_id).content_type).to eql(content_type)
  end

  describe "#to_param" do
    it "uses the bag id" do
      bag_id = 'made_up'
      expect(Fabricate.build(factory_id, bag_id: bag_id).to_param).to eq(bag_id)
    end
  end

end

