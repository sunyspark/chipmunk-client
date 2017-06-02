require 'rails_helper'

RSpec.describe QueueItemBuilder do

  let(:config_upload_path) { Rails.application.config.upload['upload_path'] }
  let(:config_storage_path) { Rails.application.config.upload['storage_path'] }
  let(:request) { Fabricate(:request) }

  before(:each) do
    allow(BagMoveJob).to receive(:perform_later)
  end

  describe "#create" do
    subject { described_class.new().create(request) }

    it { is_expected.to be_an_instance_of(QueueItem)}
    it { is_expected.to be_valid }

    it "contains the request" do
      expect(subject.request).to eql(request)
    end
    it "has no bag" do
      expect(subject.bag).to be_nil
    end
    it "enqueues a BagMoveJob to /<storage_path>/:bag_id" do
      upload_path = File.join(config_upload_path, request.user.username, request.bag_id)
      storage_path = File.join(config_storage_path, request.bag_id)
      expect(BagMoveJob).to receive(:perform_later).with(subject, upload_path, storage_path)
    end

  end
end

