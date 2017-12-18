class ChipmunkBagValidator
  include ChipmunkValidatable

  attr_reader :errors

  def initialize(db_bag,errors=[])
    @db_bag = db_bag
    @src_path = db_bag.src_path
    @disk_bag = ChipmunkBag.new(src_path) if File.exist?(src_path)
    @errors = errors
  end

  validates condition: -> { File.exist?(src_path) },
      error: -> { "Bag does not exist at upload location #{src_path}" }

  validates condition: -> { File.exist?(src_path) },
      error: -> { "Bag does not exist at upload location #{src_path}" }

  validates condition: -> { disk_bag.valid? },
      error: -> { "Error validating bag:\n" + indent_array(disk_bag.errors.full_messages) }

  ["Metadata-URL", "Metadata-Type", "Metadata-Tagfile"].each do |tag|
    validates condition: -> { disk_bag.chipmunk_info.key?(tag) },
        error: -> { "Missing required tag #{tag} in chipmunk-info.txt" }
  end

  validates condition: -> { disk_bag.tag_files
                           .map {|f| File.basename(f) }
                           .include?(disk_bag.chipmunk_info["Metadata-Tagfile"]) },
      error: -> { "Missing referenced metadata #{disk_bag.chipmunk_info["Metadata-Tagfile"]}" }

  validates precondition: -> { Open3.capture3(db_bag.external_validation_cmd) },
      condition: ->(_, _, status) { status == 0 },
      error: ->(_, stderr, _) { "Error validating content\n" + stderr }

  validates condition:  -> { disk_bag.chipmunk_info["External-Identifier"] == db_bag.external_id },
      error: -> { "uploaded External-Identifier '#{disk_bag.chipmunk_info["External-Identifier"]}'" +
                  " does not match intended ID '#{db_bag.external_id}'" }


  private

  def indent_array(array, width = 2)
    array.map {|s| " " * width + s }.join("\n")
  end

  attr_reader :src_path, :db_bag, :disk_bag

end
