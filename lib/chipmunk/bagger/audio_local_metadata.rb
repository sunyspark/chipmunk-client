# frozen_string_literal: true

require "find"
require "chipmunk/metadata_error"
require "chipmunk/bagger"

module Chipmunk
  class Bagger::AudioLocalMetadata < Bagger
    def initialize(params)
      super(params)
      @metadata_url  = params[:metadata_url]
      @metadata_type = params[:metadata_type]
      @metadata_path = params[:metadata_path]
    end

    # Moves data from src_path to bag_path/data, adds metadata, and generates
    # appropriate manifests
    def make_bag
      move_files_to_bag
      bag.add_tag_file(metadata_target_file, metadata_path)
      bag.write_chipmunk_info(common_tags.merge(audio_metadata))
      bag.manifest!
    end

    private

    attr_reader :metadata_url, :metadata_type, :metadata_path

    def common_tags
      super.merge("Chipmunk-Content-Type" => "audio")
    end

    def metadata_target_file
      "#{@metadata_type.downcase}.xml"
    end

    def audio_metadata
      { "Metadata-URL"     => metadata_url,
        "Metadata-Type"    => metadata_type,
        "Metadata-Tagfile" => metadata_target_file }
    end

  end
end
