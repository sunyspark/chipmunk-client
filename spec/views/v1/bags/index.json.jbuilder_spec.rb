require "rails_helper"

describe "/v1/bags/index.json.jbuilder" do
  let(:bag) do
    double(:bag,
      bag_id: SecureRandom.uuid,
      user: double(:user, email: Faker::Internet.email),
      external_id: SecureRandom.uuid,
      storage_location: "#{Faker::Lorem.word}/path",
      external_service: "mirlyn",
      content_type: "fake",
      created_at: Time.at(0),
      updated_at: Time.now
    )
  end
  let(:expected) do
    {
      bag_id: bag.bag_id,
      user: bag.user.email,
      external_id: bag.external_id,
      content_type: bag.content_type,
      created_at: bag.created_at.to_formatted_s(:default),
      updated_at: bag.updated_at.to_formatted_s(:default)
    }
  end
  let(:admin_user) { double(:admin_user, admin?: true) }
  let(:unprivileged_user) { double(:unpriv_user, admin?: false) }


  context "when the user is underprivileged" do
    before(:each) { assign(:current_user, unprivileged_user) }
    it "renders correct json w/o storage_location" do
      assign(:bags, [bag])
      render
      expect(JSON.parse(rendered, symbolize_names: true)).to eql([expected])
    end
  end

  context "when the user is an admin" do
    before(:each) { assign(:current_user, admin_user) }
    it "renders correct json w/ storage_location" do
      assign(:bags, [bag])
      render
      expect(JSON.parse(rendered, symbolize_names: true))
        .to eql [expected.merge({storage_location: bag.storage_location})]
    end
  end
end