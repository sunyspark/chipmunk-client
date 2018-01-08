# frozen_string_literal: true

require "find"
require "audio_mets"
require "chipmunk_metadata_error"
require "chipmunk_bagger"

class ChipmunkAudioBagger < ChipmunkBagger

  def initialize(src_path:, **kwargs)
    super(**kwargs)
    # make sure src_path ends in a '/'
    src_path += "/" unless src_path[-1] == "/"
    @src_path = src_path
  end

  # Moves data from src_path to bag_path/data and generates appropriate manifests
  def process_bag

    # move everything into the data subdir if data subdir does not exist
    move_files_to_bag

    bag.write_chipmunk_info(common_tags.merge(audio_metadata))
    bag.download_metadata

  end

  private

  attr_accessor :src_path

  def audio_metadata
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

end
