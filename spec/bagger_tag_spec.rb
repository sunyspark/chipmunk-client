require "spec_helper"
require "bagger_tag"

describe BaggerTag do


  describe "::from_hash" do
    let(:json_tag) do
      JSON.parse(<<JSON)
      {
        "SomeField": {
          "fieldRequired": true,
          "defaultValue": "???",
          "valueList": [
            "???",
            "foo",
            "bar"
          ]
        }
      }
JSON

  end
    it "accepts a hash deserialized from a JSON bagger profile" do
      expect(described_class.from_hash(json_tag)).not_to be(nil)
    end

    it "has a name that matches the json hash" do
      expect(described_class.from_hash(json_tag).name).to eq("SomeField")
    end

    it "raises an exception if the provided hash has more than one key" do
      expect do
        described_class.from_hash(
        { "foo" => { "fieldRequired" => true },
          "bar" => { "fieldRequired" => true } })
      end.to raise_exception(ArgumentError)
    end

    it "raises an exception if the provided hash is empty" do
      expect { described_class.from_hash({}) }.to raise_exception(ArgumentError)
    end

    it "raises an exception if the provided hash does not have a fieldRequired key" do
      expect { described_class.from_hash({ "a": {} }) }.to raise_exception(ArgumentError)
    end

  end

  describe "#value_valid?" do
    context "with a required tag with no value list" do
      subject { BaggerTag.new(name: "SomeField", required: true) }

      it "is false when not given a value" do
        expect(subject.value_valid?(nil)).to be false
      end

      it "is true when given a value" do
        expect(subject.value_valid?("foo")).to be true
      end

      it "is true when given another value" do
        expect(subject.value_valid?("quux")).to be true
      end

    end

    context "with a required tag with a value list" do
      let(:subject) do 
        BaggerTag.new(name: "SomeField", 
                      required: true, 
                      allowed_values: ['foo','bar'])
      end

      it "is false when not given a value" do
        expect(subject.value_valid?(nil)).to be false
      end

      it "is true when given a value on the list" do
        expect(subject.value_valid?("foo")).to be true
      end

      it "is false when given a value not on the list" do
        expect(subject.value_valid?("quux")).to be false
      end
    end

    context "with an optional tag without a value list" do
      let(:subject) { BaggerTag.new(name: "SomeField", required: false) }

      it "is true when not given a value" do
        expect(subject.value_valid?(nil)).to be true
      end

      it "is true when given a value" do
        expect(subject.value_valid?("foo")).to be true
      end

      it "is true when given another value" do
        expect(subject.value_valid?("quux")).to be true
      end
    end

    context "with an optional tag with a value list" do
      let(:subject) do 
        BaggerTag.new(name: "SomeField", 
                      required: false, 
                      allowed_values: ['foo','bar'])
      end

      it "is true when not given a value" do
        expect(subject.value_valid?(nil)).to be true
      end

      it "is true when given a value on the list" do
        expect(subject.value_valid?("foo")).to be true
      end

      it "is false when given a value not on the list" do
        expect(subject.value_valid?("quux")).to be false
      end
    end
  end
end

