# frozen_string_literal: true

require "spec_helper"
require "chipmunk/bagger/video"

RSpec.describe Chipmunk::Bagger::Video do
  let(:external_id) { "12345" }
  let(:fake_uuid) { "fakeuuid" }
  let(:good_data_path) { fixture("video", "upload", "good", "data") }

  def make_bag
    described_class.new(content_type: "video",
                        external_id: external_id,
                        src_path: @src_path,
                        bag_path: @bag_path).make_bag
  end

  let(:bag_data) { File.join(@bag_path, "data") }

  context "with fixture data" do
    # set up data in safe area
    around(:each) do |example|
      Dir.mktmpdir do |tmpdir|
        @bag_path = File.join(tmpdir, "testbag")
        @src_path = File.join(tmpdir, "srcpath")
        FileUtils.cp_r(fixture_data, @src_path)
        example.run
      end
    end

    context "with stubbed Chipmunk::Bag" do
      let(:bag) do
        instance_double(Chipmunk::Bag,
          "manifest!": nil,
          write_chipmunk_info: nil,
          add_tag_file: nil,
          download_metadata: nil)
      end

      before(:each) do
        allow(SecureRandom).to receive(:uuid).and_return(fake_uuid)
        allow(Chipmunk::Bag).to receive(:new).and_return(bag)
      end

      context "with good video data" do
        let(:fixture_data) { good_data_path }

        before(:each) do
          allow(bag).to receive(:add_file_by_moving)
        end

        shared_examples_for "moves files to the data dir" do
          ["metadata.yaml", "miam0001.mov", "mipm0001.mov", "tn0001_1.jpg",
           "tn0001_2.jpg", "tn0001_3.jpg", "tn0001_4.jpg", "tn0001_5.jpg"].each do |file|
            it "moves #{file} to the data dir" do
              expect(bag).to receive(:add_file_by_moving).with(file, File.join(@src_path, file))
              make_bag
            end
          end
        end

        context "when data dir doesn't exist" do
          it_behaves_like "moves files to the data dir"
        end

        context "when the source and destination directory are the same" do
          it_behaves_like "moves files to the data dir"
        end

        it "adds the expected metadata tags" do
          expect(bag).to receive(:write_chipmunk_info).with(
            "External-Identifier" => external_id,
            "Chipmunk-Content-Type" => "video",
            "Bag-ID" => fake_uuid
          )

          make_bag
        end
      end
    end

    context "with good video data" do
      let(:fixture_data) { good_data_path }

      it "creates a valid Chipmunk::Bag" do
        make_bag
        expect(Chipmunk::Bag.new(@bag_path)).to be_valid
      end

      it "removes the empty source path" do
        make_bag
        expect(File.exist?(@src_path)).to be false
      end
    end
  end
end
