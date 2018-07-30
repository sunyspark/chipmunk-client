
# frozen_string_literal: true

require "spec_helper"
require "chipmunk/bagger_cli"

RSpec.describe Chipmunk::BaggerCLI do
  describe "#initialize" do
    it "accepts audio with a source path" do
      expect(described_class.new(["audio", "foo", "-s", "/foo/bar", "/baz/quux"])).not_to be_nil
    end

    it "accepts digital w/o source path" do
      expect(described_class.new(["digital", "foo", "/path/to/output"])).not_to be_nil
    end

    it "does not accept an undefined content type" do
      expect { described_class.new(["garbage", "foo", "/path/to/output"]) }.to raise_exception(ArgumentError)
    end

    it "raises an exception with 2 args" do
      expect { described_class.new(["foo", "/path/to/output"]) }.to raise_exception(ArgumentError)
    end

    it "raises an exception with 1 arg" do
      expect { described_class.new(["foo"]) }.to raise_exception(ArgumentError)
    end

    it "raises an exception with no args" do
      expect { described_class.new([]) }.to raise_exception(ArgumentError)
    end
  end

  describe "#bagger" do
    it "can make an audio bagger" do
      expect(described_class.new(["audio", "foo", "-s", "foo", "bar"]).bagger).to be_a(Chipmunk::Bagger::Audio)
    end

    it "can make a digital bagger" do
      expect(described_class.new(["digital", "foo", "bar"]).bagger).to be_a(Chipmunk::Bagger::Digital)
    end

    it "can make a video bagger" do
      expect(described_class.new(["video", "foo", "-s", "foo", "bar"]).bagger).to be_a(Chipmunk::Bagger::Video)
    end

    it "can make a audio bagger with local metadata" do
      expect(described_class.new(["audio", "foo", "-s", "foo", "bar",
                                  "--metadata-type", "MARC",
                                  "--metadata-path", "/somewhere/whatever.xml",
                                  "--metadata-url", "http://foo.bar/whatever.xml"]).bagger).to be_a_kind_of(Chipmunk::Bagger::AudioLocalMetadata)
    end
  end

  describe "#run" do
    it "raises a RuntimeError if the source path is specified and the destination directory exists" do
      allow(File).to receive(:exist?).with("dest_path/data").and_return(true)
      expect { described_class.new(["audio", "ext_id", "-s", "src_path", "dest_path"]).run }
        .to raise_exception(RuntimeError, /won't overwrite/)
    end

    it "calls check_bag and make_bag on the bagger" do
      cli = described_class.new(["digital", "foo", "bar"])
      expect(cli.bagger).to receive(:check_bag)
      expect(cli.bagger).to receive(:make_bag)

      cli.run
    end
  end
end
