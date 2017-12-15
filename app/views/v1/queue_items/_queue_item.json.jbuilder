# frozen_string_literal: true

json.id queue_item.id
json.status queue_item.status.to_s.upcase
json.request v1_request_path(queue_item.bag)
if queue_item.status.to_sym == :done
  json.bag v1_bag_path(queue_item.bag)
end
if queue_item.status.to_sym == :failed
  json.error queue_item.error
end

json.created_at queue_item.created_at.to_formatted_s(:default)
json.updated_at queue_item.updated_at.to_formatted_s(:default)
