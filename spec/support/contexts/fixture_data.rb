

# frozen_string_literal: true

RSpec.shared_context "fixture data" do
  # set up data in safe area
  around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      @bag_path = File.join(tmpdir, "testbag")
      @src_path = File.join(tmpdir, "srcpath")
      FileUtils.cp_r(fixture_data, @src_path)
      example.run
    end
  end
end
