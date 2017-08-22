require 'bagit'

class ChipmunkBag < BagIt::Bag
  def chipmunk_info_txt_file
    File.join bag_dir, 'chipmunk-info.txt'
  end
  
  def chipmunk_info
    read_info_file chipmunk_info_txt_file
  end

  def write_chipmunk_info(hash)
    write_info_file chipmunk_info_txt_file, hash
    add_tag_file('chipmunk-info.txt')
  end
  
end
