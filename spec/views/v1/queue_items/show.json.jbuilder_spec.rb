require "rails_helper"

describe "/v1/queue_items/show.json.jbuilder" do
  let(:queue_item) { Fabricate(:queue_item) }
  let(:expected) do
    {
      id: queue_item.id,
      request: "/v1/requests/#{queue_item.request.bag_id}",
      status: "PENDING",
      created_at: queue_item.created_at.to_formatted_s(:default),
      updated_at: queue_item.updated_at.to_formatted_s(:default)
    }
  end


  it "renders the correct json" do
    assign(:queue_item, queue_item)
    render
    expect(JSON.parse(rendered, symbolize_names: true)).to eql(expected)
  end
end