# frozen_string_literal: true

require "spec_helper"

describe Uploader do
  let(:client) do
    instance_double(ChipmunkClient)
  end
  let(:bag_id) { "14d25bcd-deaf-4c94-add7-c189fdca4692" }
  let(:rsyncer) { instance_double(BagRsyncer, upload: true) }
  let(:request) do
    # from spec/support/fixtures/test_bag
    {
      "bag_id"      => bag_id,
      "external_id" => "test_ex_id_22",
      "upload_link" => "#{Faker::Internet.email}:/#{Faker::Lorem.word}/path/#{bag_id}"
    }
  end

  let(:queue_item) do
    {
      "id"     => 1,
      "status" => "DONE",
      "bag"    => "/v1/bags/#{bag_id}"
    }
  end

  before(:each) do
    allow(client).to receive(:post)
      .with("/v1/requests", anything)
      .and_return(request)
    allow(client).to receive(:post)
      .with("/v1/requests/#{request["bag_id"]}/complete")
      .and_return(queue_item)
  end

  subject do
    described_class.new(fixture("test_bag"), client: client, rsyncer: rsyncer)
  end

  context "when the bag is not already stored" do
    before(:each) { request["stored"] = false }

    context "when bag validation succeeds" do
      it "uploads the bag" do
        expect(rsyncer).to receive(:upload).with(request["upload_link"])
        subject.upload
      end

      it "prints a success message" do
        expect { subject.upload }.to output(/#{request["external_id"]}.*success/).to_stdout
      end

      it "returns true" do
        expect(subject.upload).to be true
      end
    end

    context "when bag validation fails" do
      let(:queue_item) do
        {
          "status" => "FAILED",
          "error" =>  "something went wrong\n" \
            "here are the details"
        }
      end

      it "prints an error message" do
        expect { subject.upload }.to output(/#{request["external_id"]}.*failure/).to_stdout
      end

      it "returns false" do
        expect(subject.upload).to be false
      end

      it "formats the validation failure" do
        expect { subject.upload }.to output(/something went wrong\nhere are the details/).to_stdout
      end
    end

    context "when the bag's external ID mismatches the external ID in the request" do
      let(:different_external_id_request) { request.merge("external_id" => "gobbledygook") }

      before(:each) do
        allow(client).to receive(:post)
          .with("/v1/requests", anything)
          .and_return(different_external_id_request)
      end

      it "prints an error message" do
        expect { subject.upload }.to output(/expected.*"gobbledygook".*"test_ex_id_22"/).to_stdout
      end

      it "does not upload the bag" do
        expect(rsyncer).not_to receive(:upload)
        subject.upload
      end
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
        message: "599 Having a bad problem")
    end

    before(:each) do
      allow(client).to receive(:post).and_raise(ChipmunkClientError.new(rest_error))
    end

    it "prints the error message" do
      expect { subject.upload }.to output(/some problem/).to_stdout
    end
  end
end
