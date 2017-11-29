require "spec_helper"

describe Uploader do

  let(:mock_service) do
    instance_double(ChipmunkClient, post: {}, get: {}) 
  end
  let(:mock_rsyncer) { instance_double(BagRsyncer,upload: true) }
  let(:mock_request) { Fabricate.attributes_for(:request) }
  let(:item_id) { mock_request["item_id"] }
      
  before(:each) do 
    allow(mock_service).to receive(:post)
      .with("/v1/requests",anything)
      .and_return(mock_request)

    allow(mock_service).to receive(:get)
      .with("/v1/queue/#{item_id}")
      .and_return( { status: "DONE" } )
  end

  subject do
    described_class.new("foo",fixture('test_bag'),service: mock_service, rsyncer: mock_rsyncer)
  end

  it "uploads the bag" do
    expect(mock_rsyncer).to receive(:upload).with(mock_request["upload_link"])
    subject.upload
  end

  context "when something goes wrong" do
    let(:rest_error) do
      double(:rest_error,
             response: '{ "exception": "some problem"}',
             message: '599 Having a bad problem')
    end

    before(:each) do 
      allow(mock_service).to receive(:post).and_raise(ChipmunkClientError.new(rest_error))
    end

    it "prints the error message" do
      expect{subject.upload}.to output(/some problem/).to_stdout
    end
  end
end
