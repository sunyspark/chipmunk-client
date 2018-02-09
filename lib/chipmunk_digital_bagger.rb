# frozen_string_literal: true

require "securerandom"
require "chipmunk_bag"

class ChipmunkDigitalBagger < ChipmunkBagger


  # validates the bag at bag_path, adds chipmunk_info.txt, and updates the
  # manifest.
  def make_bag
    unless bag.valid?
      raise "Error validating bag:\n" + bag.errors.full_messages.join("\n")
    end

    bag.write_chipmunk_info(common_tags)
    bag.manifest!
  end

  private

end
