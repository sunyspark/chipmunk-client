require 'rails_helper'

RSpec.describe DigitalRequest, type: :model do
  [:bag_id, :user_id, :external_id, :upload_link].each do |field|
    it "#{field} is required" do
      expect(Fabricate.build(:digital_request, field => nil)).to_not be_valid
    end
  end

  it "#content_type is :digital" do
    expect(Fabricate.build(:digital_request).content_type).to eql(:digital)
  end

end
