class BagMoveJob < ApplicationJob
  def perform(queue_item, src_path, dest_path)
    File.rename(src_path,dest_path)

    # When a bag is just a completed request 
    #  - start a transaction that updates the request to complete
    #  - move the bag into place
    #  - success: commit the transaction
    #  - failure (exception) - transaction automatically rolls back
    queue_item.transaction do
      binding.pry
      queue_item.bag = bag_type(queue_item).create!(
        bag_id: queue_item.request.bag_id,
        user: queue_item.user,
        storage_location: dest_path,
        external_id: queue_item.request.external_id
      )
      queue_item.save!
    end
  end

  private

  def bag_type(queue_item)
    case queue_item.request.content_type
    when :audio
      AudioBag
    when :digital
      DigitalBag
    else
      raise ArgumentError, "there has to be a better way of doing this"
    end
  end
end
