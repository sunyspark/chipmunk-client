require "spec_helper"
require "bagger_profile"

describe BaggerProfile do
  subject do 
    BaggerProfile.new(File.join(Rails.root, "spec", "support","fixtures","test-profile.json")) 
  end

  let(:errors) { [] }

  it "parses a profile" do
    expect(subject).not_to be(nil)
  end

  context "with valid bag info" do
    let(:bag_info) { { "Foo" => "bar", "Baz" => "quux" } }

    it "is true with bag info valid according to a given profile" do
      expect(subject.valid?(bag_info)).to be true
    end

    it "does not report any errors" do
      subject.valid?(bag_info,errors: errors)
      expect(errors).to be_empty
    end
  end

  context "with bag info missing a required tag" do
    let(:bag_info) {  { "Baz" => "quux" } }

    it "is false" do
      expect(subject.valid?(bag_info)).to be false
    end

    it "reports an error about the missing tag" do
      subject.valid?(bag_info,errors: errors)
      expect(errors).to include a_string_matching(/Foo.*required/)
    end
  end

  context "with a tag with a disallowed value" do
    let(:bag_info) { { "Foo" => "bar", "Baz" => "disallowed" } }

    it "is false" do
      expect(subject.valid?(bag_info)).to be false
    end

    it "reports an error about the disallowed value" do
      subject.valid?(bag_info,errors: errors)
      expect(errors).to include a_string_matching(/allowed/)
    end
  end

  context "when an optional tag is missing" do
    let(:bag_info) { { "Foo" => "bar" } }

    it "is true" do
      expect(subject.valid?(bag_info)).to be true
    end

    it "does not report any errors" do
      subject.valid?(bag_info,errors: errors)
      expect(errors).to be_empty
    end
  end


end

