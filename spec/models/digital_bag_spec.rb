require 'rails_helper'

RSpec.describe DigitalBag, type: :model do
  [:bag_id, :user_id, :external_id, :storage_location].each do |field|
    it "#{field} is required" do
      expect(Fabricate.build(:digital_bag, field => nil)).to_not be_valid
    end
  end

  it "#content_type is :digital" do
    expect(Fabricate.build(:digital_bag).content_type).to eql(:digital)
  end
end
