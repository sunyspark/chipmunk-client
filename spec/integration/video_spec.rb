# frozen_string_literal: true

require "rails_helper"
require "fileutils"

RSpec.describe "video validation integration", integration: true do
  it_behaves_like "a validation integration" do
    let(:content_type) { "video" }
    let(:external_id) { "foo" }
    let(:validation_script) { "validate_video.pl" }
    let(:expected_error) { /Error validating.*Unexpected files/m }
  end
end
