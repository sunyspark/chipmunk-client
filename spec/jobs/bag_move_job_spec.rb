require 'rails_helper'

RSpec.describe BagMoveJob do
  let (:queue_item) { Fabricate(:queue_item) }
  let (:srcpath) { 'foo' }
  let (:destpath) { 'bar' }

  class InjectedError < RuntimeError
  end

  describe '#perform' do
    subject { described_class.perform_now(queue_item,srcpath,destpath) }

    context "when the move succeeds" do
      before(:each) do
        allow(File).to receive(:rename).with(srcpath,destpath).and_return true
      end

      it "moves the bag" do
        expect(File).to receive(:rename).with(srcpath,destpath)
        subject
      end

      it "on success, updates the queue_item to status :done" do
        subject
        expect(queue_item.status).to eql("done")
      end
    end

    context "when there is an error" do
      before(:each) do
        allow(File).to receive(:rename).with(srcpath,destpath).and_raise InjectedError, 'injected error'
      end

      it "re-raises the exception" do
        expect { subject }.to raise_exception(InjectedError)
      end

      it "updates the queue_item to status 'failed'" do
        begin
          subject
        rescue InjectedError
        end

        expect(queue_item.status).to eql("failed")
      end

      it "records the error in the queue_item" do

        begin
          subject
        rescue InjectedError
        end

        expect(queue_item.error).to match(/injected error/)
      end
    end

  end
end

