
class QueueItemBuilder

  def initialize
  end

  def create(request)
    duplicate = QueueItem.where(bag: request, status: [:pending, :done]).first
    unless duplicate.nil?
      return :duplicate, duplicate
    end

    queue_item = QueueItem.new(bag: request)
    if queue_item.valid?
      queue_item.save!
      BagMoveJob.perform_later(queue_item, request.upload_path, storage_location(request))
      return :created, queue_item
    else
      return :invalid, queue_item
    end
  end

  private

  # should get moved to a merged request/bag
  def storage_location(request)
    root = Rails.application.config.upload['storage_path']
    File.join root, request.bag_id
  end
end
