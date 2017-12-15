# frozen_string_literal: true

class BagRsyncer
  def initialize(bag_path)
    @bag_path = bag_path.chomp("/")
  end

  def upload(dest)
    raise "rsync failed" unless
    system("rsync", "-avz", "#{bag_path}/", dest)
  end

  private

  attr_accessor :bag_path
end
