require 'rails_helper'

RSpec.describe BagMoveJob do
  let (:queue_item) { Fabricate(:queue_item) }
  let (:src_path) { queue_item.bag.src_path }
  let (:dest_path) { queue_item.bag.dest_path }

  class InjectedError < RuntimeError
  end

  describe '#perform' do
    subject { described_class.perform_now(queue_item) }

    before(:each) do
      allow(File).to receive(:'exists?').with(src_path).and_return true
      allow(ChipmunkBag).to receive(:new).with(src_path).and_return(fakebag)
      allow(File).to receive(:rename).with(src_path,dest_path).and_return true
      allow(Open3).to receive(:capture3).and_return(ext_validation_result)
    end

    context "when the bag is valid and external validation succeeds" do
      let(:fakebag) { double('fake bag', valid?: true ) }
      let(:ext_validation_result) { ['','',0] }

      it "moves the bag" do
        expect(File).to receive(:rename).with(src_path,dest_path)
        subject
      end

      it "updates the queue_item to status :done" do
        subject
        expect(queue_item.status).to eql("done")
      end

      context "but the move fails" do
        before(:each) do
          allow(File).to receive(:rename).with(src_path,dest_path).and_raise InjectedError, 'injected error'
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
        expect(File).not_to receive(:rename).with(src_path,dest_path)
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
        expect(File).not_to receive(:rename).with(src_path,dest_path)
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

