require 'rails_helper'

RSpec.describe AudioBag, type: :model do
  it_behaves_like "a bag", :audio_bag, :audio
end
