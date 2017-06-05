json.id queue_item.id
json.request url_for(
  controller: "v1/requests",
  action: "show",
  bag_id: queue_item.request.bag_id
)

case queue_item.status.to_sym
when :pending
  json.status "PENDING"
when :done
  json.status "DONE"
  json.bag url_for(
    controller: "v1/bags",
    action: "show",
    bag_id: queue_item.bag.bag_id
  )
when :failed
  json.status "FAILED"
  json.error queue_item.error
end

json.created_at queue_item.created_at.to_formatted_s(:default)
json.updated_at queue_item.updated_at.to_formatted_s(:default)