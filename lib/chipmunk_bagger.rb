# frozen_string_literal: true

require "chipmunk_bag"
require "chipmunk_metadata_error"
require "audio_mets"
require "find"
require "bagit"
require "securerandom"
require "nokogiri"

class ChipmunkBagger

  attr_accessor :content_type, :external_id, :src_path, :bag_path

  def initialize(content_type, external_id, src_path, bag_path)
    @content_type = content_type
    @external_id = external_id
    # make sure src_path ends in a '/'
    src_path += "/" unless src_path[-1] == "/"
    @src_path = src_path
    @bag_path = bag_path
  end

  # Moves data from src_path to bag_path/data and generates appropriate manifests
  def make_bag
    raise ArgumentError, "Making bags for #{content_type} is not supported" unless content_type == "audio"

    # make a new bag with the given external id and content type at given path
    @bag = ChipmunkBag.new bag_path

    # move everything into the data subdir if data subdir does not exist
    move_files_to_bag

    bag.write_chipmunk_info(common_tags.merge(audio_tags))
    bag.download_metadata

    # generate the manifest and tagmanifest files
    bag.manifest!
  end

  private

  attr_accessor :bag

  def common_tags
    {
      "External-Identifier"   => external_id,
      "Chipmunk-Content-Type" => content_type,
      "Bag-ID"                => SecureRandom.uuid
    }
  end

  def move_files_to_bag
    Find.find(src_path) do |file_to_add|
      # directories will automatically be created in the bag based on the files
      # added, so we don't need to explicitly add them to the bag
      next if File.directory?(file_to_add)

      # relative_path is the destination path within the bag (relative to data)
      # file_to_add is a resolvable path on disk to an actual file.
      relative_path = remove_prefix(src_path, file_to_add)
      bag.add_file_by_moving(relative_path, file_to_add)
    end
  end

  def audio_tags
    mets_fh = bag.get("mets.xml")
    raise ChipmunkMetadataError, "Bag doesn't contain mets.xml" unless mets_fh
    mets = AudioMETS.new(mets_fh)

    { 'Metadata-URL':     mets.marcxml_url,
      'Metadata-Type':    "MARC",
      'Metadata-Tagfile': "marc.xml" }
  end

  def remove_prefix(_prefix, file)
    file.sub(/^#{src_path}/, "")
  end

end
