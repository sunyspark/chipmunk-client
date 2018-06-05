# frozen_string_literal: true

require "securerandom"
require "chipmunk/bag"

module Chipmunk
  class Bagger

    attr_accessor :content_type, :external_id, :bag_path

    def initialize(params)
      @content_type = params[:content_type]
      @external_id = params[:external_id]
      @bag_path = params[:bag_path]

      @src_path = File.join(params[:src_path], "") if params[:src_path]
    end

    # creates a new bag at bag_path, adds chipmunk_info.txt, and updates the
    # manifest.
    def make_bag
      bag.write_chipmunk_info(common_tags)
      bag.manifest!
    end

    private

    def process_bag; end

    attr_accessor :src_path

    def bag
      @bag ||= Bag.new bag_path
    end

    def common_tags
      {
        "External-Identifier"   => external_id,
        "Chipmunk-Content-Type" => content_type,
        "Bag-ID"                => bag_id
      }
    end

    def bag_id
      @bag_id ||= SecureRandom.uuid
    end

  end
end
