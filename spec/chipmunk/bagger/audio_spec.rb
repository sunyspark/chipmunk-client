# frozen_string_literal: true

require "spec_helper"
require "chipmunk/bagger/audio"

RSpec.describe Chipmunk::Bagger::Audio do
  let(:marc_url) {  "https://mirlyn.lib.umich.edu/Record/011500592.xml" }
  let(:external_id) { "12345" }
  let(:fake_uuid) { "fakeuuid" }
  let(:good_data_path) { fixture("audio", "upload", "good", "data") }

  before(:each) do
    # don't actually fetch marc
    allow(Net::HTTP).to receive(:get)
      .with(URI(marc_url))
      .and_return(File.read(fixture("marc.xml")))
  end

  let(:mets_path) { File.join(good_data_path, "mets.xml") }
  let(:bag_data) { File.join(@bag_path, "data") }

  context "with fixture data and stubbed Chipmunk::Bag" do
    include_context "fixture data"

    context "with stubbed Chipmunk::Bag" do
      include_context "stubbed Chipmunk::Bag"

      before(:each) do
        allow(bag).to receive(:get).with("mets.xml").and_return(File.open(mets_path))
      end

      context "with good audio data" do
        let(:fixture_data) { good_data_path }

        before(:each) do
          allow(bag).to receive(:add_file_by_moving)
        end

        shared_examples_for "moves files to the data dir" do
          ["am000001.wav", "pm000001.wav", "mets.xml"].each do |file|
            it "moves #{file} to the data dir" do
              expect(bag).to receive(:add_file_by_moving).with(file, File.join(@src_path, file))
              make_bag("audio")
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
            "Chipmunk-Content-Type" => "audio",
            "Bag-ID" => fake_uuid,
            'Metadata-URL': marc_url,
            'Metadata-Type': "MARC",
            'Metadata-Tagfile': "marc.xml"
          )

          make_bag("audio")
        end

        it "downloads the metadata" do
          expect(bag).to receive(:download_metadata)
          make_bag("audio")
        end

        context "when bag doesn't contain mets.xml" do
          before(:each) do
            allow(bag).to receive(:get).with("mets.xml").and_return(nil)
          end

          it "reports an error" do
            expect { make_bag("audio") }.to raise_error(Chipmunk::MetadataError, /mets.xml/)
          end
        end
      end

      context "with src data that has hierarchy" do
        let(:fixture_data) { fixture("data_hierarchy") }

        it "preserves directory hierarchy under source dir" do
          expect(bag).to receive(:add_file_by_moving).with("zero_file", File.join(@src_path, "zero_file"))
          expect(bag).to receive(:add_file_by_moving).with("one/one_file", File.join(@src_path, "one/one_file"))
          expect(bag).to receive(:add_file_by_moving).with("one/two/two_file", File.join(@src_path, "one/two/two_file"))
          make_bag("audio")
        end
      end
    end

    it_behaves_like "a bagger", "audio"
  end
end
