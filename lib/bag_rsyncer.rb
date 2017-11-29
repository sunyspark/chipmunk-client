class BagRsyncer
  def initialize(bag_path)
    @bag_path = bag_path.chomp('/')
  end

  def upload(dest)
    raise RuntimeError, 'rsync failed' unless
    system('rsync','-avz',"#{bag_path}/",dest)
  end

  private

  attr_accessor :bag_path
end

