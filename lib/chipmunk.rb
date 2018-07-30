# frozen_string_literal: true

require "chipmunk/bag_rsyncer"
require "chipmunk/cli"
require "chipmunk/client"
require "chipmunk/metadata_error"
require "chipmunk/uploader"

require "ettin"

module Chipmunk
  class << self
    def reset_config
      @config = nil
    end

    def config
      @config_files ||= default_config_files
      @config ||= Ettin.for(@config_files)
    end

    def default_config_files
      Ettin.settings_files(File.join(File.dirname(__FILE__), "..", "config"), nil)
    end

    def add_config(c)
      @config_files ||= default_config_files
      @config_files << c
    end
  end
end
