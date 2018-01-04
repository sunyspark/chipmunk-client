require "spec_helper"
require "bagger_profile"

describe BaggerProfile do
  subject do 
    BaggerProfile.new(File.join(Rails.root, "spec", "support","fixtures","test-profile.json")) 
  end

  it "parses a profile" do
    expect(subject).not_to be(nil)
  end

  it "is true with bag info valid according to a given profile" do
    expect(subject.valid?({ "Foo" => "bar", "Baz" => "quux" })).to be true
  end

  it "is false with bag info missing a required tag" do
    expect(subject.valid?({ "Baz" => "quux" })).to be false
  end

  it "is false with bag info with a tag with a disallowed value" do
    expect(subject.valid?( { "Foo" => "bar", "Baz" => "disallowed" })).to be false
  end

  it "is true if an optional tag is missing" do
    expect(subject.valid?({ "Foo" => "bar" })).to be true
  end


end

