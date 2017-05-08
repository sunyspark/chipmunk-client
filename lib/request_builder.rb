

# Given a hash of parameters, this builds a request of an
# appropriate type. It does the following:
#
# Contacts third-party services to ensure metadata is present and accurate.
# Provisions a location for the file to be uploaded
# Populates the upload_link field of the request
#
# This process is synchronous.
class RequestBuilder

  def initialize(args)

  end

  # Returns the request.
  # Controller currently assumes this saves it.
  def build

  end

end