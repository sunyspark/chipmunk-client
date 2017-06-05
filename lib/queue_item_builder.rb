
class QueueItemBuilder

  def initialize
  end

  def create(request)
    queue_item = QueueItem.new(request: request, bag: nil)
    if queue_item.valid?
      BagMoveJob.perform_later(queue_item, request.upload_path, storage_location(request))
      queue_item.save!
    end
    return queue_item
  end

  private

  # should get moved to a merged request/bag
  def storage_location(request)
    root = Rails.application.config.upload['storage_path']
    File.join root, request.bag_id
  end
end
