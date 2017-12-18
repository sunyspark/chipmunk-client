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
    subject { described_class.perform_now(queue_item) }

    before(:each) do
      allow(File).to receive(:'exist?').with(src_path).and_return true
      allow(ChipmunkBag).to receive(:new).with(src_path).and_return(fakebag)
      allow(fakebag).to receive(:chipmunk_info).and_return(chipmunk_info)
      allow(fakebag).to receive(:tag_files).and_return(tag_files)
      allow(File).to receive(:rename).with(src_path, dest_path).and_return true
      allow(Open3).to receive(:capture3).and_return(ext_validation_result)
    end

    shared_examples_for "a failed bag" do |error_pattern|
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
        expect(queue_item.error).to match(error_pattern)
      end
    end

    context "when the bag is valid" do
      let(:fakebag) { double("fake bag", valid?: true) }
      let(:ext_validation_result) { ["", "", 0] }
      let(:tag_files) { good_tag_files }

      context "and its metadata matches the queue item" do
        let(:chipmunk_info) { chipmunk_info_good }

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

      context "but its external ID does not match the queue item" do
        let(:chipmunk_info) { chipmunk_info_good.merge("External-Identifier" => "something-different") }
        it_behaves_like "a failed bag", /External-Identifier/
      end

      context "but its bag ID does not match the queue item" do
        let(:chipmunk_info) { chipmunk_info_good.merge("Bag-ID" => "something-different") }
        it_behaves_like "a failed bag", /Bag-ID/
      end
      
      context "but its package type does not match the queue item" do
        let(:chipmunk_info) { chipmunk_info_good.merge("Chipmunk-Content-Type" => "something-different") }
        it_behaves_like "a failed bag", /Chipmunk-Content-Type/
      end
    end

    context "when the bag is invalid" do
      let(:errors) { double("errors", full_messages: ["injected error"]) }
      let(:fakebag) { double("fake bag", valid?: false, errors: errors) }
      let(:ext_validation_result) { ["", "", 0] }
      let(:chipmunk_info) { {} }
      let(:tag_files) { good_tag_files }

      it_behaves_like "a failed bag", /Error validating.*\n  injected error$/

      it "does not move the bag" do
        expect(File).not_to receive(:rename).with(src_path, dest_path)
        subject
      end

      it "does not try to run external validation" do
        expect(Open3).not_to receive(:capture3)
        subject
      end
    end

    context "when the bag is valid but does not include metadata " do
      let(:fakebag) { double("fake bag", valid?: true) }
      let(:chipmunk_info) { chipmunk_info_good }
      let(:ext_validation_result) { ["", "", 0] }
      let(:tag_files) { [] }

      it_behaves_like "a failed bag", /Missing.*marc.xml/
    end

    context "when the bag is valid but does not include metadata tags" do
      let(:fakebag) { double("fake bag", valid?: true) }
      let(:chipmunk_info) { chipmunk_info_db }
      let(:ext_validation_result) { ["", "", 0] }
      let(:tag_files) { [] }

      it_behaves_like "a failed bag", /Missing.*Metadata-/
    end

    context "when the bag is valid and has metadata but external validation fails" do
      let(:fakebag) { double("fake bag", valid?: true) }
      let(:chipmunk_info) { chipmunk_info_good }
      let(:ext_validation_result) { ["external output", "external error", 1] }
      let(:tag_files) { good_tag_files }

      it_behaves_like "a failed bag", /external error/
    end
  end
end
