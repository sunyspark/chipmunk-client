class ChipmunkBagValidator
  include ChipmunkValidatable

  attr_reader :errors

  def initialize(db_bag,errors=[])
    @db_bag = db_bag
    @src_path = db_bag.src_path
    @disk_bag = ChipmunkBag.new(src_path) if File.exist?(src_path)
    @errors = errors
  end

  validates "bag must exist on disk at src_path",
    condition: -> { File.exist?(src_path) },
    error: -> { "Bag does not exist at upload location #{src_path}" }

  validates "bag on disk must be ChipmunkBag#valid?",
    condition: -> { disk_bag.valid? },
    error: -> { "Error validating bag:\n" + indent_array(disk_bag.errors.full_messages) }

  { "External-Identifier" => :external_id,
    "Bag-ID" => :bag_id,
    "Chipmunk-Content-Type" => :content_type }.each_pair do |file_key,db_key|
    validates "#{file_key} in bag on disk matches bag in database",
      precondition: -> { [disk_bag.chipmunk_info[file_key], db_bag.public_send(db_key)] },
      condition:  ->(file_val,db_val) { file_val == db_val },
      error: ->(file_val,db_val) { "uploaded #{file_key} '#{file_val}'" +
                  " does not match expected value '#{db_val}'" }
  end


  validates "Bag ID in bag on disk matches bag in database",
    condition:  -> { disk_bag.chipmunk_info["Bag-ID"] == db_bag.bag_id },
    error: -> { "uploaded Bag-ID '#{disk_bag.chipmunk_info["Bag-ID"]}'" +
                " does not match intended ID '#{db_bag.bag_id}'" }

  ["Metadata-URL", "Metadata-Type", "Metadata-Tagfile"].each do |tag|
    validates "chipmunk-info.txt has required tag #{tag}",
      condition: -> { disk_bag.chipmunk_info.key?(tag) },
      error: -> { "Missing required tag #{tag} in chipmunk-info.txt" }
  end

  validates "bag on disk has referenced metadata files",
    condition: -> { disk_bag.tag_files
                    .map {|f| File.basename(f) }
                    .include?(disk_bag.chipmunk_info["Metadata-Tagfile"]) },
    error: -> { "Missing referenced metadata #{disk_bag.chipmunk_info["Metadata-Tagfile"]}" }

  validates "bag on disk passes external validation",
    only_if: -> { db_bag.external_validation_cmd },
    precondition: -> { Open3.capture3(db_bag.external_validation_cmd) },
    condition: ->(_, _, status) { status == 0 },
    error: ->(_, stderr, _) { "Error validating content\n" + stderr }

  validates "bag on disk meets bagger profile",
    only_if: -> { db_bag.bagger_profile },
    condition: -> { BaggerProfile.new(db_bag.bagger_profile).valid?(disk_bag.bag_info, errors: errors) },
    error: -> { "Not valid according to bagger profile" }

  private

  def indent_array(array, width = 2)
    array.map {|s| " " * width + s }.join("\n")
  end

  attr_reader :src_path, :db_bag, :disk_bag

end
