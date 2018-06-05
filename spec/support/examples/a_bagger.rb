# frozen_string_literal: true

shared_examples_for "a bagger" do |content_type|
  context "with good data" do
    let(:fixture_data) { good_data_path }

    it "creates a valid Chipmunk::Bag" do
      make_bag(content_type)
      expect(Chipmunk::Bag.new(@bag_path)).to be_valid
    end

    it "removes the empty source path" do
      make_bag(content_type)
      expect(File.exist?(@src_path)).to be false
    end
  end
end
