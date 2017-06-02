require 'rails_helper'

RSpec.describe DigitalRequest, type: :model do

  it_behaves_like "a request", :digital_request

  it "#content_type is :digital" do
    expect(Fabricate.build(:digital_request).content_type).to eql(:digital)
  end

end
