# frozen_string_literal: true

require "find"
require "chipmunk/bagger"

module Chipmunk
  class VideoBagger < Bagger

    # Moves data from src_path to bag_path/data, adds metadata, and generates
    # appropriate manifests
    def make_bag

      # move everything into the data subdir if data subdir does not exist
      move_files_to_bag
      bag.write_chipmunk_info(common_tags)
      bag.manifest!

    end

    private

    def remove_prefix(_prefix, file)
      file.sub(/^#{src_path}/, "")
    end

    def move_files_to_bag
      Find.find(src_path) do |file_to_add|
        # directories will automatically be created in the bag based on the files
        # added, so we don't need to explicitly add them to the bag
        next if File.directory?(file_to_add)

        # relative_path is the destination path within the bag (relative to data)
        # file_to_add is a resolvable path on disk to an actual file.
        relative_path = remove_prefix(src_path, file_to_add)
        bag.add_file_by_moving(relative_path, file_to_add)
      end
    end

  end
end
