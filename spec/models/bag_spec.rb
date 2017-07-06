require 'rails_helper'

RSpec.describe Bag, type: :model do

  let(:upload_path) { Rails.application.config.upload['upload_path'] }
  let(:upload_link) { Rails.application.config.upload['rsync_point'] }
  let(:storage_path) { Rails.application.config.upload['storage_path'] }

  [:bag_id, :user_id, :external_id, :storage_location, :content_type].each do |field|
    it "#{field} is required" do
      expect(Fabricate.build(:bag, field => nil)).to_not be_valid
    end
  end

  [:bag_id, :external_id].each do |field|
    it "#{field} must be unique" do
      expect {
        2.times { Fabricate(:bag, field.to_sym => "test") }
      }.to raise_error ActiveRecord::RecordNotUnique
    end
  end

  it "has an source path based on the user and the bag id" do
    user = Fabricate.build(:user, username: 'someuser')
    request = Fabricate.build(:bag, user: user, bag_id: 1)
    expect(request.src_path).to eq(File.join(upload_path,'someuser','1'))
  end

  it "has a destination path based on the storage path and bag id" do
    user = Fabricate.build(:user, username: 'someuser')
    request = Fabricate.build(:bag, user: user, bag_id: 1)
    expect(request.dest_path).to eq(File.join(storage_path,'1'))
  end

  it "has an upload link based on the rsync point and bag id" do
    user = Fabricate.build(:user, username: 'someuser')
    request = Fabricate.build(:bag, user: user, bag_id: 1)
    expect(request.upload_link).to eq(File.join(upload_link,'1'))
  end

  describe "#external_validation_cmd" do
    it "returns a path to a command" do
      expect(Fabricate.build(:bag).external_validation_cmd).not_to be_nil
    end
  end

  describe "#to_param" do
    it "uses the bag id" do
      bag_id = 'made_up'
      expect(Fabricate.build(:bag, bag_id: bag_id).to_param).to eq(bag_id)
    end
  end

end
