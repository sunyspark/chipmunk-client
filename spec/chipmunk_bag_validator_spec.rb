# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChipmunkBagValidator do
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

  # default (good case)
  let(:fakebag) { double("fake bag", valid?: true) }
  let(:ext_validation_result) { ["", "", 0] }
  let(:bag_info) { { "Foo" => "bar", "Baz" => "quux" } }
  let(:tag_files) { good_tag_files }
  let(:chipmunk_info) { chipmunk_info_good }

  let(:errors) { [] }

  around(:each) do |example|
    old_profile = Rails.application.config.validation["bagger_profile"]
    profile_path = File.join(Rails.root,"spec","support","fixtures","test-profile.json")
    Rails.application.config.validation["bagger_profile"] = { "digital" => profile_path, "audio" => profile_path }
    example.run
    Rails.application.config.validation["bagger_profile"] = old_profile
  end

  describe "#valid?" do
    subject { described_class.new(db_bag,errors).valid? }

    before(:each) do
      allow(File).to receive(:'exist?').with(src_path).and_return true
      allow(ChipmunkBag).to receive(:new).with(src_path).and_return(fakebag)
      allow(fakebag).to receive(:chipmunk_info).and_return(chipmunk_info)
      allow(fakebag).to receive(:tag_files).and_return(tag_files)
      allow(fakebag).to receive(:bag_info).and_return(bag_info)
      allow(Open3).to receive(:capture3).and_return(ext_validation_result)
    end

    shared_examples_for "an invalid item" do |error_pattern|
      it "records the validation error" do
        subject
        expect(errors).to include a_string_matching error_pattern
      end

      it "returns false" do
        expect(subject).to be false
      end
    end


    context "when the bag is valid" do
      context "and its metadata matches the queue item" do
        it "returns true" do
          expect(subject).to be true
        end
      end

      context "but its external ID does not match the queue item" do
        let(:chipmunk_info) { chipmunk_info_good.merge("External-Identifier" => "something-different") }
        it_behaves_like "an invalid item", /External-Identifier/
      end

      context "but its bag ID does not match the queue item" do
        let(:chipmunk_info) { chipmunk_info_good.merge("Bag-ID" => "something-different") }
        it_behaves_like "an invalid item", /Bag-ID/
      end
      
      context "but its package type does not match the queue item" do
        let(:chipmunk_info) { chipmunk_info_good.merge("Chipmunk-Content-Type" => "something-different") }
        it_behaves_like "an invalid item", /Chipmunk-Content-Type/
      end
    end

    context "when the bag is invalid" do
      let(:bag_errors) { double("bag_errors", full_messages: ["injected error"]) }
      let(:fakebag) { double("fake bag", valid?: false, errors: bag_errors) }

      it_behaves_like "an invalid item", /Error validating.*\n  injected error$/

      it "does not try to run external validation" do
        expect(Open3).not_to receive(:capture3)
        subject
      end
    end

    context "when the bag is valid but does not include metadata " do
      let(:tag_files) { [] }

      it_behaves_like "an invalid item", /Missing.*marc.xml/
    end

    context "when the bag is valid but does not include metadata tags" do
      let(:chipmunk_info) { chipmunk_info_db }
      let(:tag_files) { [] }

      it_behaves_like "an invalid item", /Missing.*Metadata-/
    end

    context "when the bag is valid and has metadata but external validation fails" do
      let(:chipmunk_info) { chipmunk_info_good }
      let(:ext_validation_result) { ["external output", "external error", 1] }

      it_behaves_like "an invalid item", /external error/
    end
    
    context "with a bagger profile and bag not valid according to the profile" do
      let(:bag_info) { { "Baz" => "quux" } }

      it_behaves_like "an invalid item", /Foo.*required/
    end
  end
end
