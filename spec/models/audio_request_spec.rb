require 'rails_helper'

RSpec.describe AudioRequest, type: :model do

  it_behaves_like "a request", :audio_request


  it "#content_type is :audio" do
    expect(Fabricate.build(:audio_request).content_type).to eql(:audio)
  end

end
