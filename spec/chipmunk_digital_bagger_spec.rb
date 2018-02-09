# frozen_string_literal: true

require "spec_helper"
require "chipmunk_bagger"

RSpec.describe ChipmunkDigitalBagger do
  let(:external_id) { "12345" }
  let(:fakeuuid) { "fakeuuid" }
  let(:fixture_data) { fixture("digital", "pre-chipmunk") }

  def make_bag
    described_class.new(content_type: "digital",
                        external_id: external_id,
                        bag_path: @bag_path).make_bag
  end

  let(:bag_data) { File.join(@bag_path, "data") }

  context "with fixture data" do
    # set up data in safe area
    around(:each) do |example|
      Dir.mktmpdir do |tmpdir|
        @bag_path = File.join(tmpdir, "testbag")
        FileUtils.cp_r(fixture_data, @bag_path)
        example.run
      end
    end

    context "with stubbed ChipmunkBag" do
      let(:bag) do
        instance_double(ChipmunkBag,
          "manifest!": nil,
          "valid?": true,
          "errors": double(:errors, full_messages: []),
          write_chipmunk_info: nil,
          add_tag_file: nil,
          download_metadata: nil)
      end

      before(:each) do
        allow(SecureRandom).to receive(:uuid).and_return(fakeuuid)
        allow(ChipmunkBag).to receive(:new).and_return(bag)
      end

      it "adds the expected metadata tags" do
        expect(bag).to receive(:write_chipmunk_info).with(
          "External-Identifier" => external_id,
          "Chipmunk-Content-Type" => "digital",
          "Bag-ID" => fakeuuid,
        )

        make_bag
      end

      it "validates the existing bag before manifesting it" do
        expect(bag).to receive(:valid?).ordered
        expect(bag).to receive(:manifest!).ordered

        make_bag
      end

      it "raises an exception if the bag is not valid" do
        allow(bag).to receive(:valid?).and_return(false)

        expect{make_bag}.to raise_exception(RuntimeError)
      end

    end

    it "creates a valid ChipmunkBag" do
      make_bag
      expect(ChipmunkBag.new(@bag_path)).to be_valid
    end
  end
end
