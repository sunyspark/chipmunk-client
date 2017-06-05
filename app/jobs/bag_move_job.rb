class BagMoveJob < ApplicationJob
  def perform(queue_item, src_path, dest_path, fs = Filesystem.new)
    fs.mkdir_p dest_path
    fs.cp src_path, dest_path
    fs.rm src_path

    transaction do
      queue_item.bag = bag_type.create!(
        bag_id: queue_item.request.bag_id,
        user: queue_item.user,
        storage_location: dest_path
      )
      queue_item.save!
    end
  end

  private

  def bag_type
    case queue_item.request.content_type
    when "audio"
      AudioBag
    when "digital"
      DigitalBag
    else
      raise ArgumentError, "there has to be a better way of doing this"
    end
  end
end