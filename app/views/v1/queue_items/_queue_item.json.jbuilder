json.id queue_item.id
json.request url_for(
  controller: "v1/requests",
  action: "show",
  bag_id: queue_item.request.bag_id
)
json.status "PENDING"
json.created_at queue_item.created_at.to_formatted_s(:default)
json.updated_at queue_item.updated_at.to_formatted_s(:default)