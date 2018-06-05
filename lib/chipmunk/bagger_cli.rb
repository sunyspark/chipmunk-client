require "chipmunk/bagger"
require "optparse"

module Chipmunk
  class BaggerCLI

    attr_reader :bagger

    def initialize(args)
      parse_options(args)
      @bagger = make_bagger
    end

    def run
      bagger.make_bag
    end

    private

    attr_reader :content_type, :external_id, :src_path, :bag_path

    def make_bagger
      class_for(content_type).new({content_type: content_type,
                                   external_id: external_id,
                                   src_path: src_path,
                                   bag_path: bag_path})
    end


    def class_for(content_type)
      case content_type
      when "audio"
        Chipmunk::AudioBagger
      when "digital"
        Chipmunk::DigitalBagger
      when "video"
        Chipmunk::VideoBagger
      else
        raise ArgumentError, "No processor for content type #{content_type}"
      end
    end

    def parse_options(args)
      usage = "Usage: #{$PROGRAM_NAME} [-s SOURCE_PATH] CONTENT_TYPE EXTERNAL_ID OUTPUT_PATH"

      OptionParser.new do |opts|
        opts.banner = usage

        opts.on("-s", "--source-path [PATH]", "Path to source data") do |src_path|
          @src_path = src_path
        end
      end.parse!(args)

      raise ArgumentError, usage if args.size != 3

      (@content_type, @external_id, @bag_path) = args
    end

  end
end
