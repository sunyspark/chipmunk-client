require "spec_helper"

describe Uploader do

  let(:client) do
    instance_double(ChipmunkClient, post: {}, get: {})
  end
  let(:rsyncer) { instance_double(BagRsyncer,upload: true) }
  let(:request) {
    {
      bag_id: SecureRandom.uuid,
      user: Faker::Internet.user_name,
      external_id: SecureRandom.uuid,
      content_type: "fake",
      upload_link: "#{Faker::Internet.email}:/#{Faker::Lorem.word}/path",
      created_at: Time.at(0),
      updated_at: Time.now
    }
  }

  let(:item_id) { request["item_id"] }

  before(:each) do
    allow(client).to receive(:post)
      .with("/v1/requests",anything)
      .and_return(request)

    allow(client).to receive(:get)
      .with("/v1/queue/#{item_id}")
      .and_return( { status: "DONE" } )
  end

  subject do
    described_class.new("foo",fixture('test_bag'),client: client, rsyncer: rsyncer)
  end

  context "when the bag is not stored" do
    before(:each) { request["stored"] = false }

    it "uploads the bag" do
      expect(rsyncer).to receive(:upload).with(request["upload_link"])
      subject.upload
    end
  end

  context "when the bag is stored" do
    before(:each) { request["stored"] = true }

    it "does not attempt to upload the bag" do
      expect(rsyncer).not_to receive(:upload)
      subject.upload
    end
  end

  context "when something goes wrong" do
    let(:rest_error) do
      double(:rest_error,
             response: '{ "exception": "some problem"}',
             message: '599 Having a bad problem')
    end

    before(:each) do
      allow(client).to receive(:post).and_raise(ChipmunkClientError.new(rest_error))
    end

    it "prints the error message" do
      expect{subject.upload}.to output(/some problem/).to_stdout
    end
  end
end
