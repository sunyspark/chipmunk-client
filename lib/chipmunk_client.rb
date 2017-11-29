require "rest_client"

class ChipmunkClientError < RuntimeError
  def initialize(rest_error)
    @rest_error = rest_error 
    super(rest_error.message)
  end

  def service_exception
    JSON.parse(rest_error.response)["exception"]
  end

  private

  attr_reader :rest_error
end

# A wrapper around RestClient to make POST and GET calls to a Chipmunk API.
class ChipmunkClient

  def initialize(url: 'http://localhost:3000',api_key: )
    @url = url
    @api_key = api_key
  end

  def post(endpoint,params = {})
    request(:post,endpoint,payload: params)
  end

  def get(endpoint)
    request(:get,endpoint)
  end

  private

  attr_accessor :url, :api_key

  def request(method,endpoint,**kwargs)
    begin
      response = RestClient::Request.execute(method: method, 
                                  url: url + endpoint,
                                  headers: auth_header,
                                  **kwargs)
      
      # Manually follows the redirect from a 201 response
      # if needed and returns the result as a JSON object.
      if response.net_http_res.is_a? Net::HTTPCreated
        response = response.follow_get_redirection
      end

      JSON.parse(response)
    rescue RestClient::InternalServerError => e
      raise ChipmunkClientError.new(e)
    end
  end

  def auth_header
    { Authorization: "Token token=#{api_key}" }
  end

end
