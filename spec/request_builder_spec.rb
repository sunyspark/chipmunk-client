require 'rails_helper'

RSpec.describe RequestBuilder do

  let(:config_rsync_point) { Rails.application.config.upload['rsync_point'] }
  let(:config_upload_path) { Rails.application.config.upload['upload_path'] }
  let(:user) { Fabricate(:user) }

  describe '#create' do
    subject { described_class.new.create(params) }

    context "when given audio params" do
      let(:params) { {content_type: 'audio',
                      user: user,
                      bag_id: 1} }

      it { is_expected.to be_an_instance_of(AudioRequest)}

      context "with user parameters" do
        it "returns a Request with the configured upload link" do
          expect(subject.upload_link).to match(/^#{config_rsync_point}/)
        end
      end
    end

    context "when given digital forensics params" do
      let(:params) { {content_type: 'digital' }}

      it { is_expected.to be_an_instance_of(DigitalRequest) }
    end

    context "when building two different requests" do
      let (:params1) { {content_type: 'audio', bag_id: '1', 
                        external_id: 'foo', user: user} }
      let (:request1) { described_class.new().create(params1) }

      let (:params2) { {content_type: 'audio', bag_id: '2', 
                        external_id: 'bar', user: user } }
      let (:request2) { described_class.new().create(params2) }

      it "returns a different upload link" do
        expect(request1.upload_link).not_to eq(request2.upload_link)
      end
      
    end
  end
end

