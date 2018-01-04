require "spec_helper"
require "bagger_tag"

describe BaggerTag do


  describe "::from_hash" do
    let(:json_tag) do
      JSON.parse(<<JSON)
      {
        "SomeField": {
          "fieldRequired": true,
          "valueList": [
            "allowed_value",
            "another_allowed_value"
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
        { "SomeField" => { "fieldRequired" => true },
          "AnotherField" => { "fieldRequired" => true } })
      end.to raise_exception(ArgumentError)
    end

    it "raises an exception if the provided hash is empty" do
      expect { described_class.from_hash({}) }.to raise_exception(ArgumentError)
    end

    it "raises an exception if the provided hash does not have a fieldRequired key" do
      expect { described_class.from_hash({ "SomeField": {} }) }.to raise_exception(ArgumentError)
    end

  end

  describe "#value_valid?" do
    let(:errors) { [] }

    shared_context "true with no errors with value" do |value|
      it "is true" do
        expect(subject.value_valid?(value)).to be true
      end

      it "does not report any errors" do
        subject.value_valid?(value,errors: errors)
        expect(errors).to be_empty
      end
    end

    def expect_error_with_value(value,error_pattern)
      subject.value_valid?(value,errors: errors)
      expect(errors).to include a_string_matching error_pattern
    end

    context "with a required tag with no value list" do
      subject { BaggerTag.new(name: "SomeField", required: true) }

      it "is false when not given a value" do
        expect(subject.value_valid?(nil)).to be false
      end

      it "reports an error when not given a value" do
        expect_error_with_value(nil,/required/)
      end

      it_behaves_like "true with no errors with value", "allowed_value"
      it_behaves_like "true with no errors with value", "some_other_value"

    end

    context "with a required tag with a value list" do
      let(:subject) do 
        BaggerTag.new(name: "SomeField", 
                      required: true, 
                      allowed_values: ['allowed_value','another_allowed_value'])
      end

      it "is false when not given a value" do
        expect(subject.value_valid?(nil)).to be false
      end

      it "reports an error when not given a value" do
        expect_error_with_value(nil,/required/)
      end

      it_behaves_like "true with no errors with value", "allowed_value"

      it "is false when given a value not on the list" do
        expect(subject.value_valid?("some_other_value")).to be false
      end

      it "reports an error when given a value not on the list" do
        expect_error_with_value("some_other_value",/not an allowed value/)
      end
    end

    context "with an optional tag without a value list" do
      let(:subject) { BaggerTag.new(name: "SomeField", required: false) }

      it_behaves_like "true with no errors with value", nil
      it_behaves_like "true with no errors with value", "allowed_value"
      it_behaves_like "true with no errors with value", "some_other_value"
    end

    context "with an optional tag with a value list" do
      let(:subject) do 
        BaggerTag.new(name: "SomeField", 
                      required: false, 
                      allowed_values: ['allowed_value','another_allowed_value'])
      end

      it_behaves_like "true with no errors with value", nil
      it_behaves_like "true with no errors with value", "allowed_value"

      it "is false when given a value not on the list" do
        expect(subject.value_valid?("some_other_value")).to be false
      end

      it "reports an error when given a value not on the list" do
        expect_error_with_value("some_other_value",/not an allowed value/)
      end
    end
  end
end

