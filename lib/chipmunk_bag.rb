# frozen_string_literal: true

require "bagit"
require "net/http"

class ChipmunkBag < BagIt::Bag
  def chipmunk_info_txt_file
    File.join bag_dir, "chipmunk-info.txt"
  end

  def chipmunk_info
    return {} unless File.exist?(chipmunk_info_txt_file)
    read_info_file chipmunk_info_txt_file
  end

  def write_chipmunk_info(hash)
    write_info_file chipmunk_info_txt_file, hash
    add_tag_file("chipmunk-info.txt")
  end

  def download_metadata
    File.write(File.join(bag_dir, chipmunk_info["Metadata-Tagfile"]),
      Net::HTTP.get(URI(chipmunk_info["Metadata-URL"])))

    add_tag_file(chipmunk_info["Metadata-Tagfile"])
  end

  # Moves a file from the source location into the bag.
  #
  # dest_path should be relative to the bag's data directory; parent
  # directories will be created if they do not exist.
  def add_file_by_moving(base_path, src_path)
    path = File.join(data_dir, base_path)
    raise "Bag file exists: #{base_path}" if File.exist? path
    FileUtils.mkdir_p File.dirname(path)

    f = FileUtils.mv src_path, path

    write_bag_info
    f
  end

end
