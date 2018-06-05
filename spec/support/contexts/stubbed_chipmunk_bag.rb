
# frozen_string_literal: true

RSpec.shared_context "stubbed Chipmunk::Bag" do
  let(:bag) do
    instance_double(Chipmunk::Bag,
      "manifest!": nil,
      write_chipmunk_info: nil,
      add_tag_file: nil,
      download_metadata: nil)
  end

  before(:each) do
    allow(SecureRandom).to receive(:uuid).and_return(fake_uuid)
    allow(Chipmunk::Bag).to receive(:new).and_return(bag)
  end
end
