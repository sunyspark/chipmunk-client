require 'bagit'
require 'rest-client'
require 'pry'
require 'json'
require_relative './chipmunk_bag'

CHIPMUNK_URL = "http://localhost:3000"

class Uploader
  def initialize(api_key,bag_path)
    @api_key = api_key
    @bag_path = bag_path.chomp('/')
    @request_params = request_params_from_bag(bag_path)
  end

  def upload
    req = make_request
    rsync_bag(req["upload_link"])
    qitem = complete_request(req)
    print_result(wait_for_bag(qitem))
  end

  def bag_id
    request_params[:bag_id]
  end

  private

  attr_accessor :request_params, :api_key, :bag_path

  def print_result(qitem_result)
    if qitem_result["status"] == "DONE"
      pp chipmunk_get(qitem_result["bag"])
    else
      pp qitem_result
    end
  end

  def require_chipmunk_bag_tags(tags)
  ["External-Identifier", 
   "Bag-ID", 
   "Chipmunk-Content-Type"].each do |field| 
      raise RuntimeError, "missing #{field}" unless tags[field]
    end
  end

  def request_params_from_bag(bag_path)
    bag = ChipmunkBag.new bag_path
    raise RuntimeError, bag.errors.full_messages if !bag.valid?

    tags = bag.chipmunk_info
    require_chipmunk_bag_tags(tags)

    {external_id: tags['External-Identifier'],
     content_type: tags['Chipmunk-Content-Type'],
     bag_id: tags['Bag-ID']}
  end

  def auth_header
    { Authorization: "Token token=#{api_key}" }
  end


  def make_request
    chipmunk_post("/v1/requests", request_params)
  end

  def rsync_bag(upload_link)
    # append trailing / to bag path here so we actually put the bag instead of
    # a directory containing the bag in the upload target
    raise RuntimeError, 'rsync failed' unless
      system('rsync','-avz',"#{bag_path}/",upload_link)
  end

  def complete_request(request)
    chipmunk_post("/v1/requests/#{bag_id}/complete")
  end

  def wait_for_bag(qitem)
    result = qitem
    loop do
      # update qitem
      return result if result["status"] != "PENDING"
      puts "Waiting for queue item to be processed"
      sleep 10
      result = chipmunk_get("/v1/queue/#{qitem["id"]}")
    end
  end

  def chipmunk_post(endpoint,params = {})
    chipmunk_request(:post,endpoint,payload: params)
  end

  def chipmunk_get(endpoint)
    chipmunk_request(:get,endpoint)
  end
  
  # Manually follows the redirect from a 201 response
  # if needed and returns the result as a JSON object.
  def follow_redir_and_parse(response) 
    # follow redirection from 201; avoid magic integer
    if response.net_http_res.is_a? Net::HTTPCreated
      response = response.follow_get_redirection
    end

    JSON.parse(response)
  end

  def chipmunk_request(method,endpoint,**kwargs)
    begin
    follow_redir_and_parse(RestClient::Request.execute(method: method, 
                                url: CHIPMUNK_URL + endpoint,
                                headers: auth_header,
                                **kwargs))
    rescue RestClient::InternalServerError => e
      puts e.to_s
      puts JSON.parse(e.response)["exception"]
      exit 1
    end
  end
end
