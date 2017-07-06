require 'rails_helper'

RSpec.describe QueueItemBuilder do

  let(:config_upload_path) { Rails.application.config.upload['upload_path'] }
  let(:config_storage_path) { Rails.application.config.upload['storage_path'] }

  before(:each) do
    allow(BagMoveJob).to receive(:perform_later)
  end

  shared_examples "a QueueItemBuilder invocation that returns a duplicate" do
    it "returns :duplicate" do
      expect(subject).to contain_exactly(:duplicate, anything)
    end
    it "returns the duplicate queue_item" do
      expect(subject).to contain_exactly(anything, existing)
    end
  end

  shared_examples "a QueueItemBuilder invocation that creates a new QueueItem" do
    it "returns :created" do
      expect(subject).to contain_exactly(:created, anything)
    end
    it "returns the created queue_item" do
      _, queue_item = subject
      expect(queue_item).to be_an_instance_of(QueueItem)
    end
    it "the queue_item belongs to the request" do
      _, queue_item = subject
      expect(queue_item.bag).to eql(request)
    end
    it "the queue_item is pending" do
      _, queue_item = subject
      expect(queue_item.pending?).to be true
    end
    it "enqueues a BagMoveJob to /<storage_path>/:bag_id" do
      upload_path = File.join(config_upload_path, request.user.username, request.bag_id)
      storage_path = File.join(config_storage_path, request.bag_id)
      _, queue_item = subject
      expect(BagMoveJob).to have_received(:perform_later).with(queue_item)
    end
  end

  describe "#create" do
    let(:request) { Fabricate(:request) }
    subject { described_class.new.create(request) }
    context "duplicate queue_item with status==:done" do
      let!(:existing) { Fabricate(:queue_item, bag: request, status: :done) }
      it_behaves_like "a QueueItemBuilder invocation that returns a duplicate"
    end
    context "duplicate queue_item with  status==:pending" do
      let!(:existing) { Fabricate(:queue_item, bag: request, status: :pending) }
      it_behaves_like "a QueueItemBuilder invocation that returns a duplicate"
    end
    context "duplicate queue_item with  status==:failed" do
      let!(:existing) { Fabricate(:queue_item, bag: request, status: :failed) }
      it_behaves_like "a QueueItemBuilder invocation that creates a new QueueItem"
      it "does not return the existing queue item" do
        _, queue_item = subject
        expect(queue_item).to_not eql(existing)
      end
    end
    context "no duplicate queue_item" do
      it_behaves_like "a QueueItemBuilder invocation that creates a new QueueItem"
    end
    context "with an invalid request" do
      let(:request) { Fabricate.build(:request, external_id: nil) }
      it "returns :invalid" do
        expect(subject).to contain_exactly(:invalid, anything)
      end
      it "returns the invalid queue_item" do
        expect(subject).to contain_exactly(anything, an_instance_of(QueueItem))
      end
    end
    
  end
end

