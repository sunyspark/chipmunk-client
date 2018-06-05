# frozen_string_literal: true

require "securerandom"
require "chipmunk/bag"

module Chipmunk
  class Bagger

    attr_accessor :content_type, :external_id, :bag_path

    def initialize(params)
      @content_type = params[:content_type]
      @external_id = params[:external_id]
      @bag_path = params[:bag_path]

      @src_path = File.join(params[:src_path], "") if params[:src_path]
    end

    def check_bag
      if src_path && File.exist?(File.join(bag_path, "data"))
        raise "Source path specified and #{bag_path}/data already exists; won't overwrite"
      end

      if File.exist?(File.join(bag_path, "chipmunk-info.txt"))
        raise "chipmunk-info.txt already exists, won't overwrite"
      end
    end

    protected

    attr_accessor :src_path

    def bag
      @bag ||= Bag.new bag_path
    end

    def common_tags
      {
        "External-Identifier"   => external_id,
        "Chipmunk-Content-Type" => content_type,
        "Bag-ID"                => bag_id
      }
    end

    def move_files_to_bag
      return unless src_path

      Find.find(src_path) do |file_to_add|
        # directories will automatically be created in the bag based on the files
        # added, so we don't need to explicitly add them to the bag
        next if File.directory?(file_to_add)

        # relative_path is the destination path within the bag (relative to data)
        # file_to_add is a resolvable path on disk to an actual file.
        relative_path = remove_prefix(src_path, file_to_add)
        bag.add_file_by_moving(relative_path, file_to_add)
      end

      FileUtils.rmdir src_path if Dir.empty?(src_path)
    end

    private

    def remove_prefix(_prefix, file)
      file.sub(/^#{src_path}/, "")
    end

    def bag_id
      @bag_id ||= SecureRandom.uuid
    end

  end
end
