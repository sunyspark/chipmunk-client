require 'bagit'
require 'rest-client'
require 'pry'
require 'json'
require_relative './chipmunk_bag'
require_relative './chipmunk_client'
require_relative './bag_rsyncer'

class Uploader
  def initialize(api_key,bag_path,service: ChipmunkClient.new(api_key: api_key),rsyncer: BagRsyncer.new(bag_path))
    @bag_path = bag_path.chomp('/')
    @request_params = request_params_from_bag(bag_path)
    @service = service
    @rsyncer = rsyncer
  end

  def upload
    begin
      req = make_request
      rsyncer.upload(req["upload_link"])
      qitem = complete_request(req)
      print_result(wait_for_bag(qitem))
    rescue ChipmunkClientError => e
      puts e.to_s
      puts e.service_exception
      exit 1
    end
  end

  def bag_id
    request_params[:bag_id]
  end

  private

  attr_accessor :request_params, :bag_path, :service, :rsyncer

  def print_result(qitem_result)
    if qitem_result["status"] == "DONE"
      pp service.get(qitem_result["bag"])
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

  def make_request
    service.post("/v1/requests", request_params)
  end

  def complete_request(request)
    service.post("/v1/requests/#{bag_id}/complete")
  end

  def wait_for_bag(qitem)
    result = qitem
    loop do
      # update qitem
      return result if result["status"] != "PENDING"
      puts "Waiting for queue item to be processed"
      sleep 10
      result = service.get("/v1/queue/#{qitem["id"]}")
    end
  end

end
