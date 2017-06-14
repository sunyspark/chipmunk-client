

# Given a hash of parameters, this builds a request of an
# appropriate type. It does the following:
#
# Contacts third-party services to ensure metadata is present and accurate.
# Provisions a location for the file to be uploaded
# Populates the upload_link field of the request
#
# This process is synchronous.
class RequestBuilder
  def initialize(bag_id:, content_type:, external_id:, user:, fs: Filesystem.new)
    @fs = fs
    @request = Request.new(
      bag_id: bag_id,
      external_id: external_id,
      content_type: content_type,
      user: user
      )
  end

  def create
    Rails.logger.debug "making directory #{request.upload_path}"
    fs.mkdir_p request.upload_path
    request.save!
    request
  end

  private

  attr_accessor :request, :fs
end
