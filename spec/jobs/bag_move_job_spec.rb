# frozen_string_literal: true

require "rails_helper"

RSpec.describe BagMoveJob do
  CHIPMUNK_INFO_GOOD = {
    "Metadata-Type"    => "MARC",
    "Metadata-URL"     => "http://what.ever",
    "Metadata-Tagfile" => "marc.xml"
  }.freeze

  let(:queue_item) { Fabricate(:queue_item) }
  let(:src_path) { queue_item.bag.src_path }
  let(:dest_path) { queue_item.bag.dest_path }
  let(:good_tag_files) { [File.join(src_path, "marc.xml")] }

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

    context "when the bag is valid" do
      let(:fakebag) { double("fake bag", valid?: true) }
      let(:ext_validation_result) { ["", "", 0] }
      let(:chipmunk_info) { CHIPMUNK_INFO_GOOD }
      let(:tag_files) { good_tag_files }

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
      let(:chipmunk_info) { CHIPMUNK_INFO_GOOD }
      let(:ext_validation_result) { ["", "", 0] }
      let(:tag_files) { [] }

      it_behaves_like "a failed bag", /Missing.*marc.xml/
    end

    context "when the bag is valid but does not include metadata tags" do
      let(:fakebag) { double("fake bag", valid?: true) }
      let(:chipmunk_info) { {} }
      let(:ext_validation_result) { ["", "", 0] }
      let(:tag_files) { [] }

      it_behaves_like "a failed bag", /Missing.*Metadata-Tagfile/
    end

    context "when the bag is valid and has metadata but external validation fails" do
      let(:fakebag) { double("fake bag", valid?: true) }
      let(:chipmunk_info) { CHIPMUNK_INFO_GOOD }
      let(:ext_validation_result) { ["external output", "external error", 1] }
      let(:tag_files) { good_tag_files }

      it_behaves_like "a failed bag", /external error/
    end
  end
end
