# frozen_string_literal: true

require "rails_helper"
require "fileutils"

# @param content_type [String] The content type to use when constructing Bags.
#   Also used when finding fixtures: they should be placed under
#   under spec/support/fixtures/content_type/{good,bad}
# @param external_id [String] The external identifier that should be used when
#   constructing Bags.
# @param validation_script [String] The validation command to run - should be an
#   executable script under bin
# @param expected_error [Regexp] A Regexp that the expected output from
#   validating spec/support/fixtures/content_type/bad should match.
RSpec.shared_examples "a validation integration" do
  def fixture(*args)
    File.join(Rails.application.root, "spec", "support", "fixtures", *args)
  end

  before(:each) do
    @old_validation = Rails.application.config.validation[content_type]
    @old_upload_path = Rails.application.config.upload["upload_path"]
    Rails.application.config.validation[content_type] = File.join(Rails.application.root, "bin", validation_script)
    Rails.application.config.upload["upload_path"] = fixture(content_type)
    # don't actually move the bag
    allow(File).to receive(:rename).with(bag.src_path, bag.dest_path).and_return true
  end

  after(:each) do
    Rails.application.config.validation[content_type] = @old_validation
    Rails.application.config.upload["upload_path"] = @old_upload_path
  end

  # for known upload location under fixtures/video
  let(:upload_user) { Fabricate(:user, username: "upload") }
  let(:queue_item) { Fabricate(:queue_item, bag: bag) }
  let(:dest_path) { "somepath" }

  subject { BagMoveJob.perform_now(queue_item) }

  def bag_with_id(bag_id)
    Fabricate(:bag, content_type: content_type,
              storage_location: nil,
              bag_id: bag_id,
              external_id: external_id,
              user: upload_user)
  end

  context "with a valid bag" do
    let(:bag) { bag_with_id("good") }

    it "completes the queue item and moves it to the destination" do
      expect(File).to receive(:rename).with(bag.src_path, bag.dest_path)
      subject
      expect(queue_item.status).to eql("done")
      expect(queue_item.bag.storage_location).to eql(bag.dest_path)
    end
  end

  context "with an invalid bag" do
    let(:bag) { bag_with_id("bad") }
    it "reports the error and does not move the bag to storage" do
      expect(File).not_to receive(:rename).with(bag.src_path, bag.dest_path)
      subject
      expect(queue_item.error).to match(expected_error)
      expect(queue_item.bag.storage_location).to be_nil
    end
  end

  context "with a nonexistent bag" do
    let(:bag) { bag_with_id("deleteme") }
    before(:each) { FileUtils.rmtree bag.src_path }
    it "does not create a bag" do
      subject
      expect(File.exist?(bag.src_path)).to be(false)
    end
  end
end
