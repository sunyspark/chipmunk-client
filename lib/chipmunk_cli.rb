require 'optparse'
require 'yaml'
require_relative './chipmunk_client'
require_relative './uploader'
require 'ettin'

class ChipmunkCLI
  def initialize(args,client_factory: ChipmunkClient)
    @config_files = Ettin.settings_files("config",nil)
    parse_options(args)
    config ||= Ettin.for(@config_files)
    @client = client_factory.new(**config)
  end

  def run(uploader_factory: Uploader)
    bag_paths.each do |bag_path|
      puts "Uploading #{bag_path}"
      uploader_factory.new(bag_path, client: client).upload
      puts
    end
  end

  private

  attr_reader :client, :bag_paths

  USAGE = "Usage: #{$PROGRAM_NAME} [options] /path/to/bag1 /path/to/bag2 ..."

  def parse_options(args)
    OptionParser.new do |opts|
      opts.banner = USAGE

      opts.on("-c CONFIG", "--config", "Configuration file") do |c|
        @config_files << c
      end
    end.parse!(args)

    raise ArgumentError, USAGE if args.empty?

    @bag_paths = args
  end

end
