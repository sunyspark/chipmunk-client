require 'rails_helper'

RSpec.describe DigitalBag, type: :model do
  it_behaves_like "a bag", :digital_bag, :digital
end
