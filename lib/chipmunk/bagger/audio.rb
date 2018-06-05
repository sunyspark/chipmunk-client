# frozen_string_literal: true

require "find"
require "chipmunk/audio_mets"
require "chipmunk/metadata_error"
require "chipmunk/bagger"

module Chipmunk
  class Bagger::Audio < Bagger

    # Moves data from src_path to bag_path/data, adds metadata, and generates
    # appropriate manifests
    def make_bag
      move_files_to_bag
      bag.write_chipmunk_info(common_tags.merge(audio_metadata))
      bag.download_metadata
      bag.manifest!
    end

    private

    def audio_metadata
      mets_fh = bag.get("mets.xml")
      raise MetadataError, "Bag doesn't contain mets.xml" unless mets_fh
      mets = AudioMETS.new(mets_fh)

      { 'Metadata-URL':     mets.marcxml_url,
        'Metadata-Type':    "MARC",
        'Metadata-Tagfile': "marc.xml" }
    end

  end
end
