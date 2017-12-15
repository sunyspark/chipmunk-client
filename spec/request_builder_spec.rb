# frozen_string_literal: true

require "rails_helper"

RSpec.describe RequestBuilder do
  let(:user) { Fabricate(:user) }
  shared_examples "a RequestBuilder invocation that returns a duplicate" do
    it "returns :duplicate" do
      expect(subject).to contain_exactly(:duplicate, anything)
    end
    it "returns the duplicate bag" do
      expect(subject).to contain_exactly(anything, existing)
    end
  end

  shared_examples "a RequestBuilder invocation that creates a new Bag" do
    it "returns :created" do
      expect(subject).to contain_exactly(:created, anything)
    end
    it "returns the created bag" do
      expect(subject).to contain_exactly(anything, an_instance_of(Bag))
    end
  end

  shared_examples "a RequestBuilder invocation that returns an invalid Bag" do
    it "returns :invalid" do
      expect(subject).to contain_exactly(:invalid, anything)
    end
    it "returns a Bag" do
      expect(subject).to contain_exactly(anything, an_instance_of(Bag))
    end
    it "returns an invalid object" do
      _, bag = subject
      expect(bag).to be_invalid
    end
  end

  describe "#create" do
    let(:params) do
      { content_type: "audio", user: user,
        bag_id: SecureRandom.uuid, external_id: "blah" }
    end
    subject { described_class.new.create(params) }
    context "duplicate bag id" do
      let!(:existing) { Fabricate(:bag, bag_id: params[:bag_id], external_id: params[:external_id]) }
      it_behaves_like "a RequestBuilder invocation that returns a duplicate"
    end
    context "no duplicate bag" do
      it_behaves_like "a RequestBuilder invocation that creates a new Bag"
    end
    context "with no bag id" do
      let(:params) do
        { content_type: "audio", user: user,
          bag_id: nil, external_id: "blah" }
      end
      it_behaves_like "a RequestBuilder invocation that returns an invalid Bag"
    end
  end
end
