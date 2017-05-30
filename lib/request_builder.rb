

# Given a hash of parameters, this builds a request of an
# appropriate type. It does the following:
#
# Contacts third-party services to ensure metadata is present and accurate.
# Provisions a location for the file to be uploaded
# Populates the upload_link field of the request
#
# This process is synchronous.
class RequestBuilder
  def initialize
  end

  # Returns the request. Pass a hash with all the parameters necessary for
  # creation of the particular sub-request as well as the 'content_type' key to
  # control which type of request gets generated (currently, 'audio' or
  # 'digital'). Just using a hash rather than keyword parameters since Rails
  # parameters and keyword args still don't mix well.
  def create(params)
    klass_for(params.delete(:content_type))
      .create(params)
  end

  def klass_for(content_type)
    case content_type
    when "audio"
      AudioRequest
    when "digital"
      DigitalRequest
    else
      raise ArgumentError, "Unknown content type #{content_type} for request"
    end
  end

  private

  attr_accessor :params
end
