# frozen_string_literal: true

require "spec_helper"
require "chipmunk_audio_bagger"

RSpec.describe ChipmunkAudioBagger do
  DATAFILES = ["am000001.wav", "pm000001.wav", "mets.xml"].freeze
  MARCURL = "https://mirlyn.lib.umich.edu/Record/011500592.xml"
  EXTERNAL_ID = "12345"
  FAKEUUID = "fakeuuid"
  GOOD_DATA_PATH = fixture("audio", "upload", "good", "data")

  def make_bag
    described_class.new(content_type: "audio",
                        external_id: EXTERNAL_ID,
                        src_path: @src_path,
                        bag_path: @bag_path).make_bag
  end

  before(:each) do
    # don't actually fetch marc
    allow(Net::HTTP).to receive(:get)
      .with(URI(MARCURL))
      .and_return(File.read(fixture("marc.xml")))
  end

  let(:mets_path) { File.join(GOOD_DATA_PATH, "mets.xml") }
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

    context "with stubbed ChipmunkBag" do
      let(:bag) do
        instance_double(ChipmunkBag,
          "manifest!": nil,
          write_chipmunk_info: nil,
          add_tag_file: nil,
          download_metadata: nil)
      end

      before(:each) do
        allow(SecureRandom).to receive(:uuid).and_return(FAKEUUID)
        allow(ChipmunkBag).to receive(:new).and_return(bag)
        allow(bag).to receive(:get).with("mets.xml").and_return(File.open(mets_path))
      end

      context "with good audio data" do
        let(:fixture_data) { GOOD_DATA_PATH }

        before(:each) do
          allow(bag).to receive(:add_file_by_moving)
        end

        shared_examples_for "moves files to the data dir" do
          DATAFILES.each do |file|
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
            "External-Identifier" => EXTERNAL_ID,
            "Chipmunk-Content-Type" => "audio",
            "Bag-ID" => FAKEUUID,
            'Metadata-URL': MARCURL,
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
            expect { make_bag }.to raise_error(ChipmunkMetadataError, /mets.xml/)
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
      let(:fixture_data) { GOOD_DATA_PATH }

      it "creates a valid ChipmunkBag" do
        make_bag
        expect(ChipmunkBag.new(@bag_path)).to be_valid
      end
    end
  end
end
