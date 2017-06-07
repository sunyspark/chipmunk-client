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
    end

    context "when the bag is valid" do
      let(:fakebag) { double('fake bag', valid?: true ) }


      context "and the move succeeds" do
        before(:each) do 
          allow(File).to receive(:rename).with(srcpath,destpath).and_return true
        end
        it "moves the bag" do
          expect(File).to receive(:rename).with(srcpath,destpath)
          subject
        end

        it "updates the queue_item to status :done" do
          subject
          expect(queue_item.status).to eql("done")
        end
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

      it "does not move the bag" do
        expect(File).not_to receive(:rename).with(srcpath,destpath)
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


  end
end

