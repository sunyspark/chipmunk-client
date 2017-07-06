require 'rails_helper'
require 'fileutils'

RSpec.describe 'video validation integration' do
  def fixture(*args)
    File.join(Rails.application.root,"spec","support","fixtures",*args)
  end

  before(:each) do
    Rails.application.config.validation['video'] = File.join(Rails.application.root,"bin","validate_video.pl")
    Rails.application.config.upload['upload_path'] = fixture("video")
    # don't actually move the bag
    allow(File).to receive(:rename).with(bag.src_path,bag.dest_path).and_return true
  end

  # for known upload location under fixtures/video
  let(:upload_user) { Fabricate(:user, username: 'upload') }
  let(:queue_item) { Fabricate(:queue_item, bag: bag) }
  let(:dest_path) { "somepath" }

  subject { BagMoveJob.perform_now(queue_item) }

  def bag_with_id(bag_id)
    Fabricate(:bag,content_type: 'video',
              storage_location: nil,
              bag_id: bag_id,
              user: upload_user)
  end

  context 'with a valid bag' do
    let(:bag) { bag_with_id('good') }

                  
    it "completes the queue item and moves it to the destination" do
      expect(File).to receive(:rename).with(bag.src_path,bag.dest_path)
      subject
      expect(queue_item.status).to eql("done")
      expect(queue_item.bag.storage_location).to eql(bag.dest_path)
    end
  end

  context 'with an invalid bag' do
    let(:bag) { bag_with_id('bad') } 
    let(:src_path) { fixture("video","bad") } 
    it "reports the error and does not move the bag to storage" do
      expect(File).not_to receive(:rename).with(bag.src_path,bag.dest_path)
      subject
      expect(queue_item.error).to match(/Error validating.*Unexpected files/m)
      expect(queue_item.bag.storage_location).to be_nil
    end
  end

  context 'with a nonexistent bag' do
    let(:bag) { bag_with_id('nonexistent') }
    before(:each) { FileUtils.rmtree fixture("video","deleteme") }
    let(:src_path) { fixture("video","deleteme") }
    it "does not create a bag" do
      subject
      expect(File.exists?(src_path)).to be(false)
    end

  end
end
