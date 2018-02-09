require 'optparse'
require 'active_support/core_ext/hash'
require 'yaml'
require_relative './chipmunk_client'
require_relative './uploader'
require 'pry'

class ChipmunkCLI
  def initialize(args)
    parse_options(args)
    load_default_config

    @config = @config.symbolize_keys.slice(:url,:api_key)
    config[:api_key] = ENV["CHIPMUNK_API_KEY"] if ENV["CHIPMUNK_API_KEY"]

    @client = ChipmunkClient.new(**config)
  end

  def run
    bag_paths.each do |bag_path|
      puts "Uploading #{bag_path}"
      Uploader.new(bag_path, client: client).upload
      puts
    end
  end

  private

  attr_reader :client, :config, :bag_paths

  USAGE = "Usage: #{$PROGRAM_NAME} [options] /path/to/bag1 /path/to/bag2 ..."

  def parse_options(args)
    OptionParser.new do |opts|
      opts.banner = USAGE

      opts.on("-c", "--config", "Configuration file") do |c|
        @config = YAML.load(File.read(c))
      end
    end.parse!(args)

    raise ArgumentError, USAGE if args.empty?

    @bag_paths = args
  end

  def load_default_config
    default_config = "#{File.dirname(__FILE__)}/../config/client.yml"
    if File.exists?(default_config) and !@config
      @config = YAML.load(File.read(default_config)) 
    else
      @config = {}
    end
  end

end
