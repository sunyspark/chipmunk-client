require 'bagit'

class ChipmunkBag < BagIt::Bag
  def chipmunk_info_txt_file
    File.join bag_dir, 'chipmunk-info.txt'
  end
  
  def chipmunk_info
    read_info_file chipmunk_info_txt_file
  end
  
end
