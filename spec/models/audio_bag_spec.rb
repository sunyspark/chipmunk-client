require 'rails_helper'

RSpec.describe AudioBag, type: :model do
  [:bag_id, :user_id, :external_id, :storage_location].each do |field|
    it "#{field} is required" do
      expect(Fabricate.build(:audio_bag, field => nil)).to_not be_valid
    end
  end

  it "#content_type is :audio" do
    expect(Fabricate.build(:audio_bag).content_type).to eql(:audio)
  end
end
