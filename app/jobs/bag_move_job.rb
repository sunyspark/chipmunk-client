require 'open3'

class BagMoveJob < ApplicationJob
  def perform(queue_item)
    @queue_item = queue_item
    @src_path = queue_item.bag.src_path
    @dest_path = queue_item.bag.dest_path
    @errors = []

    begin
      
      # TODO when a bag is just a completed request 
      #  - if all validation succeeds:
      #    - start a transaction that updates the request to complete
      #    - move the bag into place
      #    - success: commit the transaction
      #    - failure (exception) - transaction automatically rolls back
      if bag_is_valid? and externally_validates?
        File.rename(src_path,dest_path)
        record_success
      else
        record_failure
      end

    rescue => exception
      @errors.push(exception.to_s)
      record_failure
      raise exception
    end
  end

  private

  attr_accessor :queue_item, :src_path, :dest_path

  def bag_is_valid?
    return false unless File.exists?(src_path)
    bag = ChipmunkBag.new(src_path)
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

  def externally_validates?
    stdout,stderr,status = Open3.capture3(queue_item.bag.external_validation_cmd)

    if status == 0
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

  def indent_array(array,width=2)
    array.map { |s| ' '*width + s }.join("\n")
  end
  
end
