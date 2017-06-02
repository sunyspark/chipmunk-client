
class QueueItemBuilder

  def initialize
  end

  def create(request)
    queue_item = QueueItem.new(request: request, bag: nil)
    if queue_item.valid?
      BagMoveJob.perform_later(queue_item, request.upload_path, storage_location)
      queue_item.save!
    end
    return queue_item
  end

  private

  attr_reader :request

  def storage_location
    root = Rails.application.config.upload['storage_path']
    user = request.user.username
    File.join root, user, request.bag_id
  end
end
