# frozen_string_literal: true

require "spec_helper"
require "chipmunk/bagger/audio_local_metadata"

RSpec.describe Chipmunk::Bagger::AudioLocalMetadata do
  let(:ead_url) { "http://quod.lib.umich.edu/s/sclead/eads/rossiter.xml" }
  let(:external_id) { "12345" }
  let(:fake_uuid) { "fakeuuid" }
  let(:good_data_path) { fixture("audio_local_md", "upload", "good", "data") }
  let(:bag_data) { File.join(@bag_path, "data") }
  let(:params) do
    {
      metadata_url:  ead_url,
      metadata_type: "EAD",
      metadata_path: fixture("ead.xml")
    }
  end

  context "with fixture data and stubbed Chipmunk::Bag" do
    include_context "fixture data"

    context "with stubbed Chipmunk::Bag" do
      include_context "stubbed Chipmunk::Bag"

      context "with good audio data" do
        let(:fixture_data) { good_data_path }

        before(:each) do
          allow(bag).to receive(:add_file_by_moving)
        end

        shared_examples_for "moves files to the data dir" do
          ["am000001.wav", "pm000001.wav", "mets.xml"].each do |file|
            it "moves #{file} to the data dir" do
              expect(bag).to receive(:add_file_by_moving).with(file, File.join(@src_path, file))
              make_bag("audio_local_metadata", **params)
            end
          end
        end

        it "adds the expected metadata tags" do
          expect(bag).to receive(:write_chipmunk_info).with(
            "External-Identifier" => external_id,
            "Chipmunk-Content-Type" => "audio",
            "Bag-ID" => fake_uuid,
            "Metadata-URL" => ead_url,
            "Metadata-Type" => "EAD",
            "Metadata-Tagfile" => "ead.xml"
          )

          make_bag("audio_local_metadata", **params)
        end

        it "copies the metadata" do
          expect(bag).to receive(:add_tag_file).with("ead.xml", fixture("ead.xml"))
          make_bag("audio_local_metadata", **params)
        end
      end
    end

    it_behaves_like "a bagger", "audio_local_metadata"
  end
end
