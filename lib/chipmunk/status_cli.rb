# frozen_string_literal: true

require "optparse"
require "chipmunk/client"
require "chipmunk"

module Chipmunk
  class StatusCLI
    attr_reader :bags

    def initialize(args, client_factory: Client)
      parse_options(args)
      @client = client_factory.new
    end

    def run
      bags.each do |bag|
        response = client.get("/v1/bags/#{bag}")

        if response.has_key? 'stored'
          if response['stored']
            puts "#{bag}\tdone"
          else
            puts "#{bag}\tnot_stored"
          end
        else
          puts "#{bag}\tnot_found"
        end
      end
    end

    private

    attr_reader :client, :config

    USAGE = "Usage: #{$PROGRAM_NAME} [options] id1 [id2...]"

    def parse_options(args)
      bags_from_file = []

      OptionParser.new do |opts|
        opts.banner = USAGE

        opts.on("-c CONFIG", "--config", "Configuration file") do |c|
          Chipmunk.add_config(c)
        end

        opts.on("-f FILE", "--file", "Bag file listing ids") do |filename|
          File.open(filename, 'r') do |f|
            bags_from_file += f.read
                               .lines
                               .map { |l| l.strip }
                               .delete_if { |l| l.empty? }
          end
        end
      end.parse!(args)

      @bags = bags_from_file + args

      raise ArgumentError, USAGE if bags.empty?
    end
  end
end
