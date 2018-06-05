# frozen_string_literal: true

require "bagit"
require "rest-client"
require "json"
require "chipmunk/bag"
require "chipmunk/client"
require "chipmunk/bag_rsyncer"

module Chipmunk
  class Uploader
    def initialize(bag_path, client:, rsyncer: BagRsyncer.new(bag_path), config:)
      @config = config
      bag_path = bag_path.chomp("/")
      bag = bag_at_path(bag_path)
      @request_params = request_params_from_bag(bag)
      @client = client
      @rsyncer = rsyncer
    end

    def upload
      req = make_request
      return false unless check_request(req)
      rsyncer.upload(req["upload_link"])
      qitem = complete_request(req)
      print_result(wait_for_bag(qitem))
    rescue ClientError => e
      puts e.to_s
      puts e.service_exception
    end

    def bag_id
      request_params[:bag_id]
    end

    private

    attr_accessor :request_params, :client, :rsyncer, :config

    def check_request(request)
      if request["stored"]
        puts "Bag for #{request["external_id"]} has already been uploaded"
        false
      elsif external_id != request["external_id"]
        puts "Server expected a bag with external ID \"#{request["external_id"]}\" " \
          "but the provided bag has external ID \"#{external_id}\""
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

    def bag_at_path(bag_path)
      Bag.new(bag_path).tap do |bag|
        if config.validate_before_upload && !bag.valid?
          raise "Bag is not valid:\n" + bag.errors.full_messages.join("\n")
        end
      end
    end

    def request_params_from_bag(bag)
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
        sleep 1
        result = client.get("/v1/queue/#{qitem["id"]}")
      end
    end

    def external_id
      request_params[:external_id]
    end

  end
end
