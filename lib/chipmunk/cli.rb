# frozen_string_literal: true

require "optparse"
require "yaml"
require "chipmunk/client"
require "chipmunk/uploader"
require "chipmunk"

module Chipmunk
  class CLI
    def initialize(args, client_factory: Client)
      parse_options(args)
      @client = client_factory.new
    end

    def run(uploader_factory: Uploader)
      bag_paths.map do |bag_path|
        puts "Uploading #{bag_path}"
        uploader = uploader_factory.new(bag_path,
                                        client: client,
                                        config: config)
        uploader.upload_without_waiting_for_result
        puts
        [bag_path, uploader]
      end.each do |bag_path, uploader|
        puts "Loading #{bag_path}"
        uploader.print_result_when_done
      end
    end

    private

    attr_reader :client, :bag_paths, :config

    USAGE = "Usage: #{$PROGRAM_NAME} [options] /path/to/bag1 /path/to/bag2 ..."

    def parse_options(args)
      OptionParser.new do |opts|
        opts.banner = USAGE

        opts.on("-c CONFIG", "--config", "Configuration file") do |c|
          Chipmunk.add_config(c)
        end
      end.parse!(args)

      raise ArgumentError, USAGE if args.empty?

      @bag_paths = args
    end

  end
end
