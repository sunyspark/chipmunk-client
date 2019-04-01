# frozen_string_literal: true

require "spec_helper"
require "chipmunk/status_cli"

RSpec.describe Chipmunk::StatusCLI do
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

  describe "#bags" do
    let(:bags) { described_class.new(args, client_factory: client_factory).bags }
    let(:client_factory) { double(:client_factory, new: client) }
    let(:client) { double(:client) }

    context "when given `bag1 bag2`" do
      let(:args) { %w[bag1 bag2] }

      it { expect(bags).to eq %w[bag1 bag2] }
    end

    context "when given `-f bag_file`" do
      let(:path_to_file) { "bag_file" }
      let(:args) { %w[-f bag_file] }

      before(:each) do
        allow(File).to receive(:open)
          .with(path_to_file, 'r')
          .and_yield(StringIO.new(file_contents))
      end

      context "and the file is empty" do
        let(:file_contents) { "" }

        it { expect{ bags }.to raise_error(ArgumentError) }
      end

      context "and the file has three ids in it" do
        let(:file_contents) { "id 1\nid 2\nid 3\n" }

        it { expect(bags).to eq ["id 1", "id 2", "id 3"] }
      end

      context "and the file has ids and a blank line" do
        let(:file_contents) { "id 1\nid 2\n\nid 3\n" }

        it "ignores the blank line" do
          expect(bags).to eq ["id 1", "id 2", "id 3"]
        end
      end
    end

    context "when given `-f first_bag_file -f second_bag_file`" do
      let(:path_to_first_file) { "first_bag_file" }
      let(:path_to_second_file) { "second_bag_file" }
      let(:args) { %w[-f first_bag_file -f second_bag_file] }

      before(:each) do
        allow(File).to receive(:open)
          .with(path_to_first_file, 'r')
          .and_yield(StringIO.new(first_file_contents))
        allow(File).to receive(:open)
          .with(path_to_second_file, 'r')
          .and_yield(StringIO.new(second_file_contents))
      end

      context "and the files have [id-1, id-2] and [id-3, id-4]" do
        let(:first_file_contents) { "id-1\nid-2\n" }
        let(:second_file_contents) { "id-3\nid-4\n" }

        it { expect(bags).to eq %w[id-1 id-2 id-3 id-4] }
      end
    end
  end

  describe "#run" do
    let(:run) { described_class.new(args, client_factory: client_factory).run }
    let(:client_factory) { double(:client_factory, new: client) }
    let(:client) { double(:client, get: bag_hash) }
    let(:bag_hash) { {} }
    let(:args) { ["bag1", "bag2"] }

    it "queries /v1/bags/id for each bag" do
      args.each do |bag|
        expect(client).to receive(:get).with("/v1/bags/#{bag}")
      end

      run
    end

    context 'when the id 404s' do
      let(:args) { ['bad_bag'] }
      let(:bag_hash) { { 'status' => 404, 'error' => 'Not Found' } }

      it "outputs not_found" do
        expect{ run }.to output(/bad_bag\tnot_found/).to_stdout
      end
    end

    context 'when the bag is stored' do
      let(:args) { ['existing_bag'] }
      let(:bag_hash) { { 'stored' => true } }

      it "outputs done" do
        expect{ run }.to output(/existing_bag\tdone/).to_stdout
      end
    end

    context 'when the bag is not stored' do
      let(:args) { ['known_bag'] }
      let(:bag_hash) { { 'stored' => false } }

      it "outputs not_stored" do
        expect{ run }.to output(/known_bag\tnot_stored/).to_stdout
      end
    end
  end
end
