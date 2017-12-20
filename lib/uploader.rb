# frozen_string_literal: true

require "bagit"
require "rest-client"
require "pry"
require "json"
require_relative "./chipmunk_bag"
require_relative "./chipmunk_client"
require_relative "./bag_rsyncer"

class Uploader
  def initialize(bag_path, client:, rsyncer: BagRsyncer.new(bag_path))
    @bag_path = bag_path.chomp("/")
    @request_params = request_params_from_bag(bag_path)
    @client = client
    @rsyncer = rsyncer
  end

  def upload
    req = make_request
    return false unless check_request(req)
    rsyncer.upload(req["upload_link"])
    qitem = complete_request(req)
    print_result(wait_for_bag(qitem))
  rescue ChipmunkClientError => e
    puts e.to_s
    puts e.service_exception
  end

  def bag_id
    request_params[:bag_id]
  end

  private

  attr_accessor :request_params, :bag_path, :client, :rsyncer

  def check_request(request)
    if request["stored"]
      puts "Bag for #{request["external_id"]} has already been uploaded"
      false
    elsif external_id != request["external_id"]
      puts "Server expected a bag with external ID \"#{request["external_id"]}\" but the provided bag has external ID \"#{external_id}\""
      false
    else
      true
    end
  end

  def print_result(qitem_result)
    if qitem_result["status"] == "DONE"
      puts "#{external_id} uploaded successfully"
      true
    else
      puts "#{external_id} upload failure"
      puts qitem_result["error"]
      false
    end
  end

  def require_chipmunk_bag_tags(tags)
    ["External-Identifier",
     "Bag-ID",
     "Chipmunk-Content-Type"].each do |field|
      raise "missing #{field}" unless tags[field]
    end
  end

  def request_params_from_bag(bag_path)
    bag = ChipmunkBag.new bag_path
    raise bag.errors.full_messages unless bag.valid?

    tags = bag.chipmunk_info
    require_chipmunk_bag_tags(tags)

    { external_id:  tags["External-Identifier"],
      content_type: tags["Chipmunk-Content-Type"],
      bag_id:       tags["Bag-ID"] }
  end

  def make_request
    client.post("/v1/requests", request_params)
  end

  def complete_request(_request)
    client.post("/v1/requests/#{bag_id}/complete")
  end

  def wait_for_bag(qitem)
    result = qitem
    loop do
      # update qitem
      return result if result["status"] != "PENDING"
      puts "Waiting for queue item to be processed"
      sleep 10
      result = client.get("/v1/queue/#{qitem["id"]}")
    end
  end

  def external_id
    request_params[:external_id]
  end

end
