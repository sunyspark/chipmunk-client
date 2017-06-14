require 'rails_helper'

RSpec.describe RequestBuilder do

  let(:config_rsync_point) { Rails.application.config.upload['rsync_point'] }
  let(:config_upload_path) { Rails.application.config.upload['upload_path'] }
  let(:user) { Fabricate(:user) }

  describe "#create" do
    let(:fs) { double(:fs, mkdir_p: nil) }
    let(:params) do
      { content_type: 'audio', user: user,
        bag_id: SecureRandom.uuid, external_id: "blah",
        fs: fs
      }
    end

    it "creates a Request" do
      expect(described_class.new(params).create).to be_an_instance_of(Bag)
    end

    it "creates the directory at the upload path" do
      request = described_class.new(params.merge(fs: fs)).create
      expect(fs).to have_received(:mkdir_p).with(request.upload_path)
    end

  end
end

