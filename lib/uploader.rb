require 'bagit'
require 'rest-client'
require 'pry'
require 'json'
require_relative './chipmunk_bag'

DARK_BLUE_ENDPOINT = "http://localhost:3000"

class Uploader
  def initialize(api_key,content_type,bag_path)
    @api_key = api_key
    @bag_path = bag_path.chomp('/')
    @request_params = request_params_from_bag(bag_path).merge(content_type: content_type)
  end

  def upload
    req = make_request
    rsync_bag(req["upload_link"])
    qitem = complete_request(req)
    bag = wait_for_bag(qitem)
    p bag
  end

  private

  attr_accessor :request_params, :api_key, :bag_path, :bag_id

  def request_params_from_bag(bag_path)
    bag = ChipmunkBag.new bag_path
    raise RuntimeError, bag.errors.full_messages if !bag.valid?

    bag_chipmunk_info = bag.chipmunk_info
    external_id = bag_chipmunk_info['External-Identifier']
    raise RuntimeError, 'missing external id' unless external_id

    @bag_id = bag_chipmunk_info['Bag-ID']
    raise RuntimeError, 'missing bag id' unless bag_id
    
    {external_id: external_id, bag_id: bag_id}
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
