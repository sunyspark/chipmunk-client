# frozen_string_literal: true

require "open3"

class BagMoveJob < ApplicationJob
  def perform(queue_item)
    @queue_item = queue_item
    @src_path = queue_item.bag.src_path
    @dest_path = queue_item.bag.dest_path
    @errors = []

    begin
      # TODO
      #  - if all validation succeeds:
      #    - start a transaction that updates the request to complete
      #    - move the bag into place
      #    - success: commit the transaction
      #    - failure (exception) - transaction automatically rolls back
      if bag_exists? && bag_is_valid? &&
          bag_includes_metadata? && bag_externally_validates?
        FileUtils.mkdir_p(File.dirname(dest_path))
        File.rename(src_path, dest_path)
        record_success
      else
        record_failure
      end
    rescue StandardError => exception
      @errors.push(exception.to_s)
      record_failure
      raise exception
    end
  end

  private

  attr_accessor :queue_item, :src_path, :dest_path, :bag

  def bag_exists?
    if File.exist?(src_path)
      @bag = ChipmunkBag.new(src_path)
      true
    else
      @errors.push("Bag does not exist at upload location #{src_path}")
      false
    end
  end

  def bag_is_valid?
    if bag.valid?
      true
    else
      @errors.push("Error validating bag:\n" +
        indent_array(bag.errors.full_messages))
      false
    end
  end

  def record_failure
    queue_item.transaction do
      queue_item.error = @errors.join("\n\n")
      queue_item.status = :failed
      queue_item.save!
    end
  end

  def bag_includes_metadata?
    bag_has_metadata_tags? && bag_has_metadata_file?
  end

  def bag_has_metadata_tags?
    tags = bag.chipmunk_info
    has_metadata_tags = true

    ["Metadata-URL", "Metadata-Type", "Metadata-Tagfile"]
      .reject {|tag| tags[tag] }
      .each do |tag|
      has_metadata_tags = false
      @errors.push("Missing required tag #{tag} in chipmunk-info.txt")
    end

    has_metadata_tags
  end

  def bag_has_metadata_file?
    metadata_file = bag.chipmunk_info["Metadata-Tagfile"]
    if bag.tag_files.map {|f| File.basename(f) }.include?(metadata_file)
      true
    else
      @errors.push("Missing referenced metadata #{metadata_file}")
      false
    end
  end

  def bag_externally_validates?
    _, stderr, status = Open3.capture3(queue_item.bag.external_validation_cmd)

    if status.zero?
      true
    else
      @errors.push("Error validating content:\n" + stderr)
      false
    end
  end

  def record_success
    queue_item.transaction do
      queue_item.status = :done
      queue_item.save!
      queue_item.bag.storage_location = dest_path
      queue_item.bag.save!
    end
  end

  def indent_array(array, width = 2)
    array.map {|s| " " * width + s }.join("\n")
  end

end
