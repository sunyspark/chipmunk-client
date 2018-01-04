# frozen_string_literal: true

require "open3"
require "chipmunk_bag_validator"

class BagMoveJob < ApplicationJob

  def perform(queue_item,errors: [], validator: ChipmunkBagValidator.new(queue_item.bag,errors))
    @queue_item = queue_item
    @src_path = queue_item.bag.src_path
    @dest_path = queue_item.bag.dest_path

    begin
      # TODO
      #  - if all validation succeeds:
      #    - start a transaction that updates the request to complete
      #    - move the bag into place
      #    - success: commit the transaction
      #    - failure (exception) - transaction automatically rolls back
      if validator.valid?
        FileUtils.mkdir_p(File.dirname(dest_path))
        File.rename(src_path, dest_path)
        record_success
      else
        record_failure(errors)
      end
    rescue StandardError => exception
      errors << exception.to_s
      record_failure(errors)
      raise exception
    end
  end

  private

  attr_accessor :queue_item, :src_path, :dest_path

  def record_failure(errors)
    queue_item.transaction do
      queue_item.error = errors.join("\n\n")
      queue_item.status = :failed
      queue_item.save!
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

end
