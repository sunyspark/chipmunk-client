# frozen_string_literal: true

require "spec_helper"
require "chipmunk_bag"

def make_bag
  @bag = ChipmunkBag.new bag_path
end

TAGFILES = ["bag-info.txt", "bagit.txt", "chipmunk-info.txt", "manifest-md5.txt", "manifest-sha1.txt"].freeze
TAGMANIFESTS = ["tagmanifest-md5.txt", "tagmanifest-sha1.txt"].freeze

FILE_CONTENTS = "some contents blah blah blah"
METADATA_URL = "http://whatever/foo.txt"
METADATA_FILE = "whatever.txt"
INFO_HASH = { "Metadata-URL"     => METADATA_URL,
              "Metadata-Tagfile" => METADATA_FILE }.freeze
INFO_TXT = <<~TXT
  Metadata-URL: #{METADATA_URL}
  Metadata-Tagfile: #{METADATA_FILE}
TXT

def expect_manifested_tagfile(tagfile)
  TAGMANIFESTS.each do |tagmanifest|
    it "has #{tagfile} in #{tagmanifest}" do
      expect(File.readlines(File.join(@bag_path, tagmanifest))
        .map {|l| l.strip.split[1] }).to include(tagfile)
    end
  end
end

RSpec.describe ChipmunkBag do
  # set up data in safe area
  around(:each) do |example|
    Dir.mktmpdir do |tmp_dir|
      @tmp_dir = tmp_dir
      @bag_path = File.join(tmp_dir, "testbag")
      example.run
    end
  end

  let(:bag_data) { File.join(@bag_path, "data") }
  let(:chipmunk_info) { File.join(@bag_path, "chipmunk-info.txt") }

  subject { ChipmunkBag.new(@bag_path) }

  describe "#initialize" do
    it "does not create any files" do
      expect(Dir.glob("#{@bag_path}/*")).to eq []
    end
  end

  describe "#chipmunk_info" do
    context "with no chipmunk-info.txt" do
      it "returns an empty hash" do
        expect(subject.chipmunk_info).to eq({})
      end
    end

    context "with contents in chipmunk-info.txt" do
      before(:each) do
        FileUtils.mkdir_p(@bag_path)
        File.write(chipmunk_info, INFO_TXT)
      end

      it "returns a hash of its contents" do
        expect(subject.chipmunk_info).to eq(INFO_HASH)
      end
    end
  end

  describe "#write_chipmunk_info" do
    before(:each) do
      subject.write_chipmunk_info(INFO_HASH)
    end

    it "writes the given hash to chipmunk-info.txt" do
      expect(File.read(chipmunk_info)).to eq(INFO_TXT)
    end

    expect_manifested_tagfile("chipmunk-info.txt")
  end

  describe "#download_metadata" do
    before(:each) do
      tmp_md_file = File.join(@tmp_dir, "foo.txt")

      File.write(tmp_md_file, FILE_CONTENTS)

      allow(Net::HTTP).to receive(:get)
        .with(URI(METADATA_URL))
        .and_return(File.read(tmp_md_file))

      subject.write_chipmunk_info(INFO_HASH)
      subject.download_metadata
    end

    it "downloads the given metadata" do
      expect(File.read(File.join(@bag_path, METADATA_FILE))).to eq(FILE_CONTENTS)
    end

    expect_manifested_tagfile(METADATA_FILE)
  end

  describe "#add_file_by_moving" do
    let(:somefile) { "somefile.txt" }
    let(:src_file) { File.join(@tmp_dir, somefile) }

    before(:each) do
      File.write(src_file, FILE_CONTENTS)
    end

    context "when files are present in both the source and destination path" do
      before(:each) do
        FileUtils.mkdir_p(bag_data)
        FileUtils.touch(File.join(bag_data, somefile))
      end

      it "raises an error" do
        expect { subject.add_file_by_moving(somefile, src_file) }.to raise_error(RuntimeError, /exists: #{somefile}/)
      end

      it "doesn't overwrite anything" do
        begin
          subject.add_file_by_moving(somefile, src_file)
        rescue RuntimeError
          # expected (as above)
        end

        # should be the same zero-size file we created above
        expect(File.stat(File.join(bag_data, somefile)).size).to eq(0)
      end
    end

    it "moves the file from source path to dest path" do
      subject.add_file_by_moving(somefile, src_file)
      expect(File.exist?(src_file)).to be(false)
      expect(File.read(File.join(bag_data, somefile))).to eq(FILE_CONTENTS)
    end
  end
end
