

# frozen_string_literal: true

# Given a hash of parameters, this builds a request of an
# appropriate type. It does the following:
#
# Contacts third-party services to ensure metadata is present and accurate.
# Provisions a location for the file to be uploaded
# Populates the upload_link field of the request
#
# This process is synchronous.
class RequestBuilder
  def create(bag_id:, content_type:, external_id:, user:)
    duplicate = Bag.where(bag_id: bag_id).first
    unless duplicate.nil?
      return :duplicate, duplicate
    end

    request = Bag.new(
      bag_id: bag_id,
      external_id: external_id,
      content_type: content_type,
      user: user
      )
    if request.valid?
      request.save!
      return :created, request
    else
      return :invalid, request
    end
  end
end
