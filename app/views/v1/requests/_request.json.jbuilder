json.bag_id request_record.bag_id
json.user request_record.user.email
json.content_type request_record.content_type
json.upload_link request_record.upload_link
json.set! "#{request_record.external_service}_id".to_sym, request_record.external_id
json.created_at request_record.created_at.to_formatted_s(:default)
json.updated_at request_record.updated_at.to_formatted_s(:default)