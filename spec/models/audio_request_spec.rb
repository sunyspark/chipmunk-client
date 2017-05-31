require 'rails_helper'

RSpec.describe AudioRequest, type: :model do
  [:bag_id, :user_id, :external_id, :upload_link].each do |field|
    it "#{field} is required" do
      expect(Fabricate.build(:audio_request, field => nil)).to_not be_valid
    end
  end

  it "#content_type is :audio" do
    expect(Fabricate.build(:audio_request).content_type).to eql(:audio)
  end

end
