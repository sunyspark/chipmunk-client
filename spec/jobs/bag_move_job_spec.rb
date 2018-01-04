# frozen_string_literal: true

require "rails_helper"

RSpec.describe BagMoveJob do
  let(:queue_item) { Fabricate(:queue_item) }
  let(:db_bag) { queue_item.bag }
  let(:src_path) { queue_item.bag.src_path }
  let(:dest_path) { queue_item.bag.dest_path }
  let(:good_tag_files) { [File.join(src_path, "marc.xml")] }

  let(:chipmunk_info_db) do
    {
      "External-Identifier"   => db_bag.external_id,
      "Chipmunk-Content-Type" => db_bag.content_type,
      "Bag-ID"                => db_bag.bag_id
    }
  end

  let(:chipmunk_info_good) do
    chipmunk_info_db.merge(
      "Metadata-Type"         => "MARC",
      "Metadata-URL"          => "http://what.ever",
      "Metadata-Tagfile"      => "marc.xml",
    )
  end

  class InjectedError < RuntimeError
  end

  describe "#perform" do
    before(:each) do
      allow(File).to receive(:rename).with(src_path, dest_path).and_return true
    end

    context "when the bag is valid" do
      let(:validator) { double(:validator, valid?: true) }
      subject { described_class.perform_now(queue_item, validator: validator) }


      it "moves the bag" do
        expect(File).to receive(:rename).with(src_path, dest_path)
        subject
      end

      it "updates the queue_item to status :done" do
        subject
        expect(queue_item.status).to eql("done")
      end

      context "but the move fails" do
        before(:each) do
          allow(File).to receive(:rename).with(src_path, dest_path).and_raise InjectedError, "injected error"
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
      let(:validator) { double(:validator, valid?: false) }
      subject { described_class.perform_now(queue_item, errors: ['my error'], validator: validator) }

      it "does not move the bag" do
        expect(File).not_to receive(:rename).with(src_path, dest_path)
        subject
      end

      it "updates the queue_item to status 'failed'" do
        subject
        expect(queue_item.status).to eql("failed")
      end
      
      it "records the validation error" do
        subject
        expect(queue_item.error).to match(/my error/)
      end

      it "does not move the bag" do
        expect(File).not_to receive(:rename).with(src_path, dest_path)
        subject
      end
    end

  end
end
