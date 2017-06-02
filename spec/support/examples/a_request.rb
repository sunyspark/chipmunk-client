require 'rails_helper'

RSpec.shared_examples "a request" do |factory_id|
  let(:upload_path) { Rails.application.config.upload['upload_path'] }
  let(:upload_link) { Rails.application.config.upload['rsync_point'] }

  [:bag_id, :user_id, :external_id].each do |field|
    it "#{field} is required" do
      expect(Fabricate.build(factory_id, field => nil)).to_not be_valid
    end
  end

  %w(bag_id external_id).each do |field|
    describe "#{field}" do
      it "must be unique" do
        expect {
          2.times { Fabricate(factory_id, field.to_sym => "test") }
        }.to raise_error ActiveRecord::RecordNotUnique
      end
    end
  end

  it "has an upload path based on the user and the bag id" do
    user = Fabricate.build(:user, username: 'someuser')
    request = Fabricate.build(factory_id, user: user, bag_id: 1)
    expect(request.upload_path).to eq(File.join(upload_path,'someuser','1'))
  end

  it "has an upload link based on the rsync point and bag id" do
    user = Fabricate.build(:user, username: 'someuser')
    request = Fabricate.build(factory_id, user: user, bag_id: 1)
    expect(request.upload_link).to eq(File.join(upload_link,'1'))
  end

  describe "#to_param" do
    it "uses the bag id" do
      bag_id = 'made_up'
      expect(Fabricate.build(factory_id, bag_id: bag_id).to_param).to eq(bag_id)
    end
  end

end

