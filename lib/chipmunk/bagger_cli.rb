# frozen_string_literal: true

require "chipmunk/bagger"
require "chipmunk/bagger/audio"
require "chipmunk/bagger/audio_local_metadata"
require "chipmunk/bagger/digital"
require "chipmunk/bagger/video"
require "optparse"

module Chipmunk
  class BaggerCLI

    attr_reader :bagger

    def initialize(args)
      @params = {}
      parse_options(args)
      @bagger = make_bagger
    end

    def run
      bagger.check_bag
      bagger.make_bag
    end

    private

    attr_reader :content_type, :external_id, :src_path, :bag_path, :params

    def make_bagger
      class_for(content_type).new(content_type: content_type,
                                   external_id: external_id,
                                   src_path: src_path,
                                   bag_path: bag_path,
                                   **params)
    end

    def class_for(content_type)
      case content_type
      when "audio"
        params[:metadata_path] ? Chipmunk::Bagger::AudioLocalMetadata : Chipmunk::Bagger::Audio
      when "digital"
        Chipmunk::Bagger::Digital
      when "video"
        Chipmunk::Bagger::Video
      else
        raise ArgumentError, "No processor for content type #{content_type}"
      end
    end

    def parse_options(args)
      usage = "Usage: #{$PROGRAM_NAME} [-s SOURCE_PATH] CONTENT_TYPE EXTERNAL_ID OUTPUT_PATH \n" \
        "  [ --metadata-type=MARC|EAD --metadata-path=/path/to/metadata --metadata-url=http://some.where/something.xml ]"

      OptionParser.new do |opts|
        opts.banner = usage

        opts.on("-s", "--source-path [PATH]", "Path to source data") do |src_path|
          @src_path = src_path
        end

        opts.on("--metadata-type MARC|EAD", "Type of metadata to include in the tag files") do |mdtype|
          params[:metadata_type] = mdtype
        end

        opts.on("--metadata-path /path/to/metadata", "Path to metadata to include in tag files") do |mdpath|
          params[:metadata_path] = mdpath
        end

        opts.on("--metadata-url http://some.where/something.xml", "URL to metadata to include in chipmunk-info.txt") do |mdurl|
          params[:metadata_url] = mdurl
        end
      end.parse!(args)

      raise ArgumentError, usage if args.size != 3

      (@content_type, @external_id, @bag_path) = args
    end

  end
end
