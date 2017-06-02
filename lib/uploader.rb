require 'bagit'
require 'rest-client'
require 'pry'
require 'json'
require_relative './chipmunk_bag'

DARK_BLUE_ENDPOINT = "http://localhost:3000"

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
    bag = wait_for_bag(qitem)
    p bag
  end

  def bag_id
    request_params[:bag_id]
  end

  private

  attr_accessor :request_params, :api_key, :bag_path

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

  # Manually follows the redirect from a 201 response
  # if needed and returns the result as a JSON object.
  def follow_redir_and_parse(response) 
    # follow redirection from 201; avoid magic integer
    if response.net_http_res.is_a? Net::HTTPCreated
      response = response.follow_get_redirection
    end

    JSON.parse(response)
  end

  # post to requests & follow redirection (from 201 or 303)
  def make_request
    # link from result automatically follows redirection from 303
    follow_redir_and_parse(RestClient.post "#{DARK_BLUE_ENDPOINT}/v1/requests", 
      { request: request_params}, auth_header)

  end

  def rsync_bag(upload_link)
    # append trailing / to bag path here so we actually put the bag instead of
    # a directory containing the bag in the upload target
    raise RuntimeError, 'rsync failed' unless
      system('rsync','-avz',"#{bag_path}/",upload_link)
  end

  def complete_request(request)
    follow_redir_and_parse(RestClient.post "#{DARK_BLUE_ENDPOINT}/v1/requests/#{bag_id}/complete", {}, auth_header)
  end

  def wait_for_bag(qitem)
    # poll queue item status

    # TODO: error h&&ling 
    # get 200 or 303

    # get /bags/:bag_id, display
  end
end
