require 'optparse'
require 'active_support/core_ext/hash'
require 'yaml'
require_relative './chipmunk_client'
require_relative './uploader'

class ChipmunkCLI
  def initialize(args)
    parse_options
    load_default_config

    @config = @config.symbolize_keys.slice(:uri,:api_key)
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

  def parse_options
    OptionParser.new do |opts|
      opts.banner = "Usage: #{$PROGRAM_NAME} [options] /path/to/bag1 /path/to/bag2 ..."

      opts.on("-c", "--config", "Configuration file") do |c|
        @config = YAML.load(File.read(c))
      end
    end

    raise ArgumentError, "Usage: #{$PROGRAM_NAME} " if ARGV.empty?

    @bag_paths = ARGV
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
