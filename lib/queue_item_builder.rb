
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
      BagMoveJob.perform_later(queue_item)
      return :created, queue_item
    else
      return :invalid, queue_item
    end
  end

  private

end
