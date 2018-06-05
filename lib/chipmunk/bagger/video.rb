# frozen_string_literal: true

require "find"
require "chipmunk/bagger"

module Chipmunk
  class Bagger::Video < Bagger

    # Moves data from src_path to bag_path/data, adds metadata, and generates
    # appropriate manifests
    def make_bag
      move_files_to_bag
      bag.write_chipmunk_info(common_tags)
      bag.manifest!
    end

  end
end
