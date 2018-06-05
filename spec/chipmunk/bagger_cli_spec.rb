
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
      expect(described_class.new(["audio", "foo", "-s", "foo", "bar"]).bagger).to be_a_kind_of(Chipmunk::Bagger)
    end

    it "can make a digital bagger" do
      expect(described_class.new(["digital", "foo", "bar"]).bagger).to be_a_kind_of(Chipmunk::Bagger)
    end
  end
end
