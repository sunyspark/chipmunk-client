# frozen_string_literal: true

require "spec_helper"
require "chipmunk/cli"
require "ettin"

RSpec.describe Chipmunk::CLI do
  let(:client_factory) { double(:factory) }

  describe "#initialize" do
    it "raises an ArgumentError if called with no arguments" do
      expect { described_class.new([]) }.to raise_exception(ArgumentError)
    end

    it "creates a client with the default config" do
      expect(client_factory).to receive(:new)
      described_class.new(["foo", "bar"], client_factory: client_factory)
    end

    it "accepts a -c option with an overriding config" do
      described_class.new(["-c", "spec/support/fixtures/other_config.yml", "foo"])
      expect(Chipmunk.config.api_key).to eq("overriden_api_key")
    end
  end

  describe "#run" do
    it "calls the uploader with each bag_path" do
      client = double(:client)
      client_factory = double(:client_factory, new: client)

      uploader_factory = double(:uploader_factory)

      bag_paths = ["/invalid/bag1", "/invalid/bag2"]

      bag_paths.each do |path|
        uploader = double("uploader for #{path}")
        allow(uploader_factory).to receive(:new).with(path, client: client, config: anything).and_return(uploader)
        expect(uploader).to receive(:upload_without_waiting_for_result)
        expect(uploader).to receive(:print_result_when_done)
      end

      cli = described_class.new(bag_paths, client_factory: client_factory)
      cli.run(uploader_factory: uploader_factory)
    end
  end
end
