require 'rails_helper'

RSpec.describe BagMoveJob do
  let (:queue_item) { Fabricate(:queue_item) }
  let (:srcpath) { 'foo' }
  let (:destpath) { 'bar' }

  class InjectedError < RuntimeError
  end

  describe '#perform' do
    subject { described_class.perform_now(queue_item,srcpath,destpath) }

    before(:each) do
      allow(ChipmunkBag).to receive(:new).with(srcpath).and_return(fakebag)
      allow(File).to receive(:rename).with(srcpath,destpath).and_return true
      allow(Open3).to receive(:capture3).and_return(ext_validation_result)
    end

    context "when the bag is valid and external validation succeeds" do
      let(:fakebag) { double('fake bag', valid?: true ) }
      let(:ext_validation_result) { ['','',0] }

      it "moves the bag" do
        expect(File).to receive(:rename).with(srcpath,destpath)
        subject
      end

      it "updates the queue_item to status :done" do
        subject
        expect(queue_item.status).to eql("done")
      end

      context "but the move fails" do
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

    context "when the bag is invalid" do
      let(:errors) { double('errors', full_messages: ['injected error']) }
      let(:fakebag) { double('fake bag', valid?: false, errors: errors ) }
      let(:ext_validation_result) { ['','',0] }

      it "does not move the bag" do
        expect(File).not_to receive(:rename).with(srcpath,destpath)
      end

      it "does not try to run external validation" do
        expect(Open3).not_to receive(:capture3)
      end

      it "updates the queue_item to status 'failed'" do
        subject
        expect(queue_item.status).to eql('failed')
      end

      it "records the validation errors with formatting and indentation" do
        subject
        expect(queue_item.error).to match(/Error validating.*\n  injected error$/)
      end
    end

    context "when the bag is valid but external validation fails" do
      let(:fakebag) { double('fake bag', valid?: true ) }
      let(:ext_validation_result) { ['external output','external error',1] }

      it "does not move the bag" do
        expect(File).not_to receive(:rename).with(srcpath,destpath)
      end

      it "updates the queue_item to status 'failed'" do
        subject
        expect(queue_item.status).to eql('failed')
      end

      it "records the validation error" do
        subject
        expect(queue_item.error).to match(/external error/)
      end
    end


  end
end

