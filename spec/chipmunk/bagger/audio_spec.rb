# frozen_string_literal: true

require "spec_helper"
require "chipmunk/bagger/audio"

RSpec.describe Chipmunk::Bagger::Audio do
  let(:marc_url) {  "https://mirlyn.lib.umich.edu/Record/011500592.xml" }
  let(:external_id) { "12345" }
  let(:fake_uuid) { "fakeuuid" }
  let(:good_data_path) { fixture("audio", "upload", "good", "data") }

  def make_bag
    described_class.new(content_type: "audio",
                        external_id: external_id,
                        src_path: @src_path,
                        bag_path: @bag_path).make_bag
  end

  before(:each) do
    # don't actually fetch marc
    allow(Net::HTTP).to receive(:get)
      .with(URI(marc_url))
      .and_return(File.read(fixture("marc.xml")))
  end

  let(:mets_path) { File.join(good_data_path, "mets.xml") }
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
            "Chipmunk-Content-Type" => "audio",
            "Bag-ID" => fake_uuid,
            'Metadata-URL': marc_url,
            'Metadata-Type': "MARC",
            'Metadata-Tagfile': "marc.xml"
          )

          make_bag
        end

        it "downloads the metadata" do
          expect(bag).to receive(:download_metadata)
          make_bag
        end

        context "when bag doesn't contain mets.xml" do
          before(:each) do
            allow(bag).to receive(:get).with("mets.xml").and_return(nil)
          end

          it "reports an error" do
            expect { make_bag }.to raise_error(Chipmunk::MetadataError, /mets.xml/)
          end
        end
      end

      context "with src data that has hierarchy" do
        let(:fixture_data) { fixture("data_hierarchy") }

        it "preserves directory hierarchy under source dir" do
          expect(bag).to receive(:add_file_by_moving).with("zero_file", File.join(@src_path, "zero_file"))
          expect(bag).to receive(:add_file_by_moving).with("one/one_file", File.join(@src_path, "one/one_file"))
          expect(bag).to receive(:add_file_by_moving).with("one/two/two_file", File.join(@src_path, "one/two/two_file"))
          make_bag
        end
      end
    end

    context "with good audio data" do
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
