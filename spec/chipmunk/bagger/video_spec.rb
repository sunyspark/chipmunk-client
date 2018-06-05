# frozen_string_literal: true

require "spec_helper"
require "chipmunk/bagger/video"

RSpec.describe Chipmunk::Bagger::Video do
  let(:external_id) { "12345" }
  let(:fake_uuid) { "fakeuuid" }
  let(:good_data_path) { fixture("video", "upload", "good", "data") }

  let(:bag_data) { File.join(@bag_path, "data") }

  context "with fixture data" do
    include_context "fixture data"

    context "with stubbed Chipmunk::Bag" do
      include_context "stubbed Chipmunk::Bag"

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
              make_bag("video")
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

          make_bag("video")
        end
      end
    end

    it_behaves_like "a bagger", "video"
  end
end
