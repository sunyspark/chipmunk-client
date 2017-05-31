require "rails_helper"

describe "/v1/requests/index.json.jbuilder" do
  let(:request_record) do
    double(:request_record,
      bag_id: SecureRandom.uuid,
      user: double(:user, email: Faker::Internet.email),
      external_id: SecureRandom.uuid,
      upload_link: "#{Faker::Internet.email}:/#{Faker::Lorem.word}/path",
      external_service: "mirlyn",
      content_type: "fake",
      created_at: Time.at(0),
      updated_at: Time.now
    )
  end
  let(:expected) do
    {
      bag_id: request_record.bag_id,
      user: request_record.user.email,
      mirlyn_id: request_record.external_id,
      content_type: request_record.content_type,
      upload_link: request_record.upload_link,
      created_at: request_record.created_at.to_formatted_s(:default),
      updated_at: request_record.updated_at.to_formatted_s(:default)
    }
  end


  it "renders the correct json" do
    assign(:request_records, [request_record])
    render
    expect(JSON.parse(rendered, symbolize_names: true)).to eql([expected])
  end
end