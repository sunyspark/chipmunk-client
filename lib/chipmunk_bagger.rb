# frozen_string_literal: true

require "securerandom"
require "chipmunk_bag"

class ChipmunkBagger

  attr_accessor :content_type, :external_id, :bag_path

  def initialize(content_type:, external_id:, bag_path:, **kwargs)
    @content_type = content_type
    @external_id = external_id
    @bag_path = bag_path
  end

  def make_bag
    # make a new bag with the given external id and content type at given path
    @bag = ChipmunkBag.new bag_path

    process_bag
    
    # generate the manifest and tagmanifest files
    bag.manifest!
  end

  def process_bag
    bag.write_chipmunk_info(common_tags)
  end

  private

  attr_accessor :bag, :metadata_extractor

  def common_tags
    {
      "External-Identifier"   => external_id,
      "Chipmunk-Content-Type" => content_type,
      "Bag-ID"                => SecureRandom.uuid
    }
  end

end
