require 'chipmunk_bag'

class ChipmunkBagger
  
  attr_accessor :content_type, :external_id, :bag_path

  def initialize(content_type, external_id, bag_path)
    @content_type = content_type
    @external_id = external_id
    @bag_path = bag_path
  end



  def make_bag
    # move everything into the data subdir if data subdir does not exist
    move_files_to_data
    
    # make a new bag with the given external id and content type at given path
    @bag = ChipmunkBag.new bag_path

    tags = common_tags 
    tags.merge!(send("#{content_type}_tags"))

    bag.write_chipmunk_info(tags)

    # generate the manifest and tagmanifest files
    bag.manifest!
  end

  private

  attr_accessor :bag

  def common_tags
    {
      'External-Identifier' => external_id,
      'Chipmunk-Content-Type' => content_type,
      'Bag-ID' => SecureRandom.uuid
    }
  end

  def content_specific_tags
  
  end

  def move_files_to_data
    bag_data_dir = File.join(bag_path,"data")
    return if File.exists?(bag_data_dir)

    files_to_move = Dir.glob(File.join(bag_path,"*"))
    FileUtils.mkdir(bag_data_dir)
    FileUtils.mv(files_to_move,File.join(bag_path,"data"))
  end


  def audio_tags
    # extract metadata path from mets
    doc = Nokogiri::XML(File.open(File.join(bag_path,"data","mets.xml")))

    # try MARC
    marc_href_attr = doc.xpath("//mets:mdRef[@MDTYPE='MARC']/@xlink:href").first
    
    if marc_href_attr
      {'Metadata-URL': download_marc(marc_href_attr.value),
       'Metadata-Type': 'MARC'}
    else
      raise ArgumentError,"No linked MARC metadata found in mets.xml"
    end
#    end

    # otherwise try EAD?
#      ead_link = doc.xpath("//mets:mdRef[@MDTYPE='EAD']/@xlink:href")

  end

  def download_marc(catalog_url)
    # fetch the xml version of the record over https
    unless match = catalog_url.match(%r((mirlyn.lib.umich.edu/Record/\d{9}))) 
      raise ArgumentError,"Catalog URL #{catalog_url} does not match mirlyn.lib.umich.edu/Record/RECORDNUM"
    end

    url = "https://#{match[0]}.xml"

    IO.copy_stream(open(url),File.join(bag_path,'marc.xml'))
    bag.add_tag_file('marc.xml')
    
    url
  end
end
