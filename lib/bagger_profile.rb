class BaggerProfile

  def initialize(uri)
    @tags = JSON.parse(open(uri).read)["ordered"].map {|t| BaggerTag.from_hash(t) }
  end

  def valid?(bag_info,errors: [])
    tags.map {|tag| tag.value_valid?(bag_info[tag.name], errors: errors) }.reduce(true, :&)
  end

  private

  attr_reader :tags
end
